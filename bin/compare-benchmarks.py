#!/usr/bin/python

#	This script creates a CSV comparing the difference between two benchmark CSVs
#	Pass --output or -o to set an output dir, helpful for comparisons and organization (ex: -o bin/featureName-benchmarks)
#	Pass the two CSVs as direct args, no --flag-prefix needed

import os
import sys
import re

def percentChange(a, b):
	a = a if type(a) == float else float(a)
	b = b if type(b) == float else float(b)
	return (b-a)/abs(b) * 100

CSVs = []

# Default parameters
parameters = {
	"directory": "bin/benchmarks",
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
	elif arg[0:1] == "-":
		print(f"Error: Unsupported flag {arg}")
		exit(1)
	else:
		CSVs.append(arg)
		argNum += 1

csvA = open(CSVs[0], mode="r", encoding="utf-8")
csvB = open(CSVs[1], mode="r", encoding="utf-8")

aName = re.search(r"([\w\-]+)\.csv$", CSVs[0]).group(1).strip().replace("-benchmark", "")
bName = re.search(r"([\w\-]+)\.csv$", CSVs[1]).group(1).strip().replace("-benchmark", "")

csvALines = csvA.readlines()
csvBLines = csvB.readlines()

# Create the results directory
if not os.path.exists(parameters['directory']):
  os.makedirs(parameters['directory'])

outputFile = open(f"{parameters['directory']}/compare-{aName}-to-{bName}-benchmark.csv", mode="w", encoding="utf-8")
outputFile.write(f"Test,Metric,{aName},{bName},Unit,Change")
outputFile.write('\n')

headers = {}
for i, line in enumerate(csvALines):
	if i == 0:
		rawHeaders = line.split(",")
		for idx, header in enumerate(rawHeaders):
			headers[header] = idx
		continue

	aValues = line.split(",")
	bValues = csvBLines[i].split(",")

	outputFile.write("{test},{metric},{a},{b},{unit},{change:.3f}%".format(
		test=aValues[headers['Test']],
		metric=aValues[headers['Metric']],
		a = aValues[headers['Value']],
		b = bValues[headers['Value']],
		unit = aValues[headers['Unit']],
		change = percentChange(aValues[headers['Value']], bValues[headers['Value']]),
	))
	outputFile.write('\n')

outputFile.close()
