#!/usr/bin/python

#	This script runs all the benchmarks, and outputs:
#	- Flamegraphs of each benchmark
#	- A detailed csv of all the processed results
#	File names will include your git branch as a prefix, making it easier to compare changes.
#
#	Pass --output or -o to set an output dir, helpful for comparisons and organization (ex: -o bin/featureName-benchmarks)
#	Pass --runs or -r to set how many time each benchmark is run (ex: -r 5)
#	Pass --dev or -d to run tests in DEV and COMPAT_WARNINGS mode (ex: --dev)

BENCHMARK_FILES = "bin/run-*-benchmark.lua"
PROJECT_JSON = "tests.project.json"
OUTPUT_PATTERN = r"(.+) x ([\d\.]+) ([/\w]+) ±([\d\.]+)\% \((\d+) runs sampled\)"

import os
import sys
import re
import subprocess
import glob
import svg
os.system('color') # Colored output support

# Profiler output node
class Node(svg.Node):
    def __init__(self):
        svg.Node.__init__(self)
        self.function = ""
        self.source = ""
        self.line = 0
        self.ticks = 0

    def text(self):
        return self.function

    def title(self):
        if self.line > 0:
            return "{}\n{}:{}".format(self.function, self.source, self.line)
        else:
            return self.function

    def details(self, root):
        return "Function: {} [{}:{}] ({:,} usec, {:.1%}); self: {:,} usec".format(self.function, self.source, self.line, self.width, self.width / root.width, self.ticks)


# Default parameters
parameters = {
	"directory": "bin/benchmarks",
	"runs": 3,
	"dev": "",
}

# Parse command line arguments
argNum = 1
while argNum < len(sys.argv):
	arg = sys.argv[argNum]
	if arg == "-o" or arg == "--output":
		value = sys.argv[argNum+1]
		if value[0:1] != "-":
			parameters['directory'] = value
		else:
			print(f"Error: Argument for {arg} is missing, please specify an output directory")
			exit(1)

		argNum += 2
	elif arg == "-r" or arg == "--runs":
		value = sys.argv[argNum+1]
		if value[0:1] != "-":
			parameters['runs'] = int(value)
		else:
			print(f"Error: Argument for {arg} is missing, please specify a number of runs")
			exit(1)

		argNum += 2
	elif arg == "-d" or arg == "--dev":
		parameters['dev'] = " --lua.globals=__DEV__=true --lua.globals=__COMPAT_WARNINGS__=true"

		argNum += 1
	elif arg[0:1] == "-":
		print(f"Error: Unsupported flag {arg}")
		exit(1)
	else:
		argNum += 1

# Gather the path information
branch = subprocess.getoutput("git symbolic-ref --short HEAD").strip().replace("/", "-")
prefix=f"{parameters['directory']}/{branch}"
logPath = f"{prefix}-benchmark.log"

# Create the results directory
if not os.path.exists(parameters['directory']):
  os.makedirs(parameters['directory'])

logFile = open(logPath, mode="w", encoding="utf-8")
logFile.write("")
logFile.flush()

# Run each benchmark file
for test in glob.iglob(BENCHMARK_FILES):
	testName = test[8:-14]
	print(f"\033[94mRunning {testName}...\033[0m", flush=True) # Colored output since benchmarks can be noisy and this helps readability

	logFile.write(f"TEST: {testName.replace('-', ' ')}\n")
	logFile.flush()
	for i in range(1, parameters['runs']+1):
		print(f"  Run {i}", flush=True)
		runResults = subprocess.Popen(
			f"robloxdev-cli run --load.model {PROJECT_JSON} --run {test} --headlessRenderer 1 --fastFlags.overrides \"EnableDelayedTaskMethods=true\" \"FIntScriptProfilerFrequency=1000000\" \"DebugScriptProfilerEnabled=true\" \"EnableLoadModule=true\" --fastFlags.allOnLuau" + parameters['dev'],
			encoding="utf-8", stdout=logFile,
		)
		runResults.wait()
		logFile.flush()

 	# Generate flamegraph from last run data
	flameFile=f"{prefix}-{testName.replace('/', '-')}-profile.svg"

	dump = open("profile.out").readlines()
	root = Node()

	for l in dump:
		ticks, stack = l.strip().split(" ", 1)
		node = root

		for f in reversed(stack.split(";")):
			source, function, line = f.split(",")

			child = node.child(f)
			child.function = function
			child.source = source
			child.line = int(line) if len(line) > 0 else 0

			node = child

		node.ticks += int(ticks)

	svg.layout(root, lambda n: n.ticks)
	svg.display(open(flameFile, mode="w"), root, "Flame Graph", "hot", flip = True)

	print(f"Flamegraph results written to {flameFile}")
	if os.path.exists("profile.out"):
		os.remove("profile.out")

logFile.flush()
logFile.close()

# Process the benchmark data into a csv
results = {}

testName = ""
for line in open(logPath, mode="r", encoding="utf-8").readlines():
	newTestMatch = re.match(r"TEST: (.+)", line)
	if newTestMatch:
		testName = newTestMatch.group(1)
		results[testName] = {}
	else:
		metricMatch = re.match(OUTPUT_PATTERN, line)
		if metricMatch:
			metric = metricMatch.group(1)
			value = metricMatch.group(2)
			unit = metricMatch.group(3)
			deviation = metricMatch.group(4)
			samples = metricMatch.group(5)

			testResult = results.get(testName)
			if not testResult:
				testResult = {}
				results[testName] = testResult

			metricResult = testResult.get(metric)
			if not metricResult:
				metricResult = {
					"count": 0,
					"valueSum": 0,
					"unit": unit,
					"deviationSum": 0,
					"samples": 0,
				}
				testResult[metric] = metricResult

			metricResult['count'] += 1
			metricResult['valueSum'] += float(value)
			metricResult['unit'] = unit
			metricResult['deviationSum'] += float(deviation)
			metricResult['samples'] += int(samples)

# Build the csv file from the result data
outputFile = open(f"{prefix}-benchmark.csv", mode="w", encoding="utf-8")
outputFile.write("Test,Metric,Value,Unit,Deviation,Samples")
outputFile.write('\n')
for testName, testResults in results.items():
	for metric, metricResult in testResults.items():
		outputFile.write("{test},\"{metric}\",{value:.5f},{unit},\"±{deviation:.2f}%\",{samples}".format(
			test=testName,
			metric=metric,
			value=metricResult['valueSum']/metricResult['count'],
			unit=metricResult['unit'],
			deviation=metricResult['deviationSum']/metricResult['count'],
			samples=metricResult['samples'],
		))
		outputFile.write('\n')

os.remove(logPath)
outputFile.close()
print(f"Benchmark results written to {prefix}-benchmark.csv")
