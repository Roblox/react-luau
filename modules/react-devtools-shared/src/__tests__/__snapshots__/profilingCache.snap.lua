-- Jest Roblox Snapshot v1, http://roblox.github.io/jest-roblox/snapshot-testing

local exports = {}

exports[ [=[ProfilingCache should calculate a self duration based on actual children (not filtered children): CommitDetails with filtered self durations 1]=] ] = [=[

Table {
  "changeDescriptions": Table {
    "_array": Table {
      2,
      3,
      5,
    },
    "_map": Table {
      2: Table {
        "didHooksChange": false,
        "isFirstMount": true,
      },
      3: Table {
        "didHooksChange": false,
        "isFirstMount": true,
      },
      5: Table {
        "didHooksChange": false,
        "isFirstMount": true,
      },
    },
    "size": 3,
  },
  "duration": 16,
  "fiberActualDurations": Table {
    "_array": Table {
      1,
      2,
      3,
      5,
    },
    "_map": Table {
      16,
      16,
      1,
      ,
      1,
    },
    "size": 4,
  },
  "fiberSelfDurations": Table {
    "_array": Table {
      1,
      2,
      3,
      5,
    },
    "_map": Table {
      0,
      10,
      1,
      ,
      1,
    },
    "size": 4,
  },
  "interactionIDs": Table {},
  "priorityLevel": "Normal",
  "timestamp": 16,
}
]=]

exports[ [=[ProfilingCache should collect data for each commit: CommitDetails commitIndex: 0 1]=] ] = [=[

Table {
  "changeDescriptions": Table {
    "_array": Table {
      2,
      3,
      4,
      5,
    },
    "_map": Table {
      ,
      Table {
        "didHooksChange": false,
        "isFirstMount": true,
      },
      Table {
        "didHooksChange": false,
        "isFirstMount": true,
      },
      Table {
        "didHooksChange": false,
        "isFirstMount": true,
      },
      Table {
        "didHooksChange": false,
        "isFirstMount": true,
      },
    },
    "size": 4,
  },
  "duration": 12,
  "fiberActualDurations": Table {
    "_array": Table {
      1,
      2,
      3,
      4,
      5,
    },
    "_map": Table {
      12,
      12,
      0,
      1,
      1,
    },
    "size": 5,
  },
  "fiberSelfDurations": Table {
    "_array": Table {
      1,
      2,
      3,
      4,
      5,
    },
    "_map": Table {
      0,
      10,
      0,
      1,
      1,
    },
    "size": 5,
  },
  "interactionIDs": Table {},
  "priorityLevel": "Normal",
  "timestamp": 12,
}
]=]

exports[ [=[ProfilingCache should collect data for each commit: CommitDetails commitIndex: 1 1]=] ] = [=[

Table {
  "changeDescriptions": Table {
    "_array": Table {
      3,
      4,
      6,
      2,
    },
    "_map": Table {
      2: Table {
        "didHooksChange": false,
        "isFirstMount": false,
        "props": Table {
          "count",
        },
      },
      3: Table {
        "didHooksChange": false,
        "isFirstMount": false,
        "props": Table {},
      },
      4: Table {
        "didHooksChange": false,
        "isFirstMount": false,
        "props": Table {},
      },
      6: Table {
        "didHooksChange": false,
        "isFirstMount": true,
      },
    },
    "size": 4,
  },
  "duration": 13,
  "fiberActualDurations": Table {
    "_array": Table {
      3,
      4,
      6,
      2,
      1,
    },
    "_map": Table {
      13,
      13,
      0,
      1,
    },
    "size": 5,
  },
  "fiberSelfDurations": Table {
    "_array": Table {
      3,
      4,
      6,
      2,
      1,
    },
    "_map": Table {
      0,
      10,
      0,
      1,
    },
    "size": 5,
  },
  "interactionIDs": Table {},
  "priorityLevel": "Normal",
  "timestamp": 25,
}
]=]

exports[ [=[ProfilingCache should collect data for each commit: CommitDetails commitIndex: 2 1]=] ] = [=[

Table {
  "changeDescriptions": Table {
    "_array": Table {
      3,
      2,
    },
    "_map": Table {
      2: Table {
        "didHooksChange": false,
        "isFirstMount": false,
        "props": Table {
          "count",
        },
      },
      3: Table {
        "didHooksChange": false,
        "isFirstMount": false,
        "props": Table {},
      },
    },
    "size": 2,
  },
  "duration": 10,
  "fiberActualDurations": Table {
    "_array": Table {
      3,
      2,
      1,
    },
    "_map": Table {
      10,
      10,
      0,
    },
    "size": 3,
  },
  "fiberSelfDurations": Table {
    "_array": Table {
      3,
      2,
      1,
    },
    "_map": Table {
      0,
      10,
      0,
    },
    "size": 3,
  },
  "interactionIDs": Table {},
  "priorityLevel": "Normal",
  "timestamp": 35,
}
]=]

exports[ [=[ProfilingCache should collect data for each commit: CommitDetails commitIndex: 3 1]=] ] = [=[

Table {
  "changeDescriptions": Table {
    "_array": Table {
      2,
    },
    "_map": Table {
      2: Table {
        "didHooksChange": false,
        "isFirstMount": false,
        "props": Table {
          "count",
        },
      },
    },
    "size": 1,
  },
  "duration": 10,
  "fiberActualDurations": Table {
    "_array": Table {
      2,
      1,
    },
    "_map": Table {
      10,
      10,
    },
    "size": 2,
  },
  "fiberSelfDurations": Table {
    "_array": Table {
      2,
      1,
    },
    "_map": Table {
      0,
      10,
    },
    "size": 2,
  },
  "interactionIDs": Table {},
  "priorityLevel": "Normal",
  "timestamp": 45,
}
]=]

exports[ [=[ProfilingCache should collect data for each commit: imported data 1]=] ] = [=[

Table {
  "dataForRoots": Table {
    Table {
      "commitData": Table {
        Table {
          "changeDescriptions": Table {
            Table {
              2,
              Table {
                "didHooksChange": false,
                "isFirstMount": true,
              },
            },
            Table {
              3,
              Table {
                "didHooksChange": false,
                "isFirstMount": true,
              },
            },
            Table {
              4,
              Table {
                "didHooksChange": false,
                "isFirstMount": true,
              },
            },
            Table {
              5,
              Table {
                "didHooksChange": false,
                "isFirstMount": true,
              },
            },
          },
          "duration": 12,
          "fiberActualDurations": Table {
            Table {
              1,
              12,
            },
            Table {
              2,
              12,
            },
            Table {
              3,
              0,
            },
            Table {
              4,
              1,
            },
            Table {
              5,
              1,
            },
          },
          "fiberSelfDurations": Table {
            Table {
              1,
              0,
            },
            Table {
              2,
              10,
            },
            Table {
              3,
              0,
            },
            Table {
              4,
              1,
            },
            Table {
              5,
              1,
            },
          },
          "interactionIDs": Table {},
          "priorityLevel": "Normal",
          "timestamp": 12,
        },
        Table {
          "changeDescriptions": Table {
            Table {
              3,
              Table {
                "didHooksChange": false,
                "isFirstMount": false,
                "props": Table {},
              },
            },
            Table {
              4,
              Table {
                "didHooksChange": false,
                "isFirstMount": false,
                "props": Table {},
              },
            },
            Table {
              6,
              Table {
                "didHooksChange": false,
                "isFirstMount": true,
              },
            },
            Table {
              2,
              Table {
                "didHooksChange": false,
                "isFirstMount": false,
                "props": Table {
                  "count",
                },
              },
            },
          },
          "duration": 13,
          "fiberActualDurations": Table {
            Table {
              3,
              0,
            },
            Table {
              4,
              1,
            },
            Table {
              6,
              2,
            },
            Table {
              2,
              13,
            },
            Table {
              1,
              13,
            },
          },
          "fiberSelfDurations": Table {
            Table {
              3,
              0,
            },
            Table {
              4,
              1,
            },
            Table {
              6,
              2,
            },
            Table {
              2,
              10,
            },
            Table {
              1,
              0,
            },
          },
          "interactionIDs": Table {},
          "priorityLevel": "Normal",
          "timestamp": 25,
        },
        Table {
          "changeDescriptions": Table {
            Table {
              3,
              Table {
                "didHooksChange": false,
                "isFirstMount": false,
                "props": Table {},
              },
            },
            Table {
              2,
              Table {
                "didHooksChange": false,
                "isFirstMount": false,
                "props": Table {
                  "count",
                },
              },
            },
          },
          "duration": 10,
          "fiberActualDurations": Table {
            Table {
              3,
              0,
            },
            Table {
              2,
              10,
            },
            Table {
              1,
              10,
            },
          },
          "fiberSelfDurations": Table {
            Table {
              3,
              0,
            },
            Table {
              2,
              10,
            },
            Table {
              1,
              0,
            },
          },
          "interactionIDs": Table {},
          "priorityLevel": "Normal",
          "timestamp": 35,
        },
        Table {
          "changeDescriptions": Table {
            Table {
              2,
              Table {
                "didHooksChange": false,
                "isFirstMount": false,
                "props": Table {
                  "count",
                },
              },
            },
          },
          "duration": 10,
          "fiberActualDurations": Table {
            Table {
              2,
              10,
            },
            Table {
              1,
              10,
            },
          },
          "fiberSelfDurations": Table {
            Table {
              2,
              10,
            },
            Table {
              1,
              0,
            },
          },
          "interactionIDs": Table {},
          "priorityLevel": "Normal",
          "timestamp": 45,
        },
      },
      "displayName": "Parent",
      "initialTreeBaseDurations": Table {},
      "interactionCommits": Table {},
      "interactions": Table {},
      "operations": Table {
        Table {
          2,
          1,
          5,
          "Parent",
          "Child",
          "0",
          "1",
          "2",
          1,
          1,
          11,
          1,
          0,
          4,
          1,
          12000,
          1,
          2,
          5,
          1,
          0,
          1,
          0,
          4,
          2,
          12000,
          1,
          3,
          5,
          2,
          2,
          2,
          3,
          4,
          3,
          0,
          1,
          4,
          5,
          2,
          2,
          2,
          4,
          4,
          4,
          1000,
          1,
          5,
          8,
          2,
          2,
          2,
          5,
          4,
          5,
          1000,
        },
        Table {
          2,
          1,
          2,
          "Child",
          "2",
          1,
          6,
          5,
          2,
          2,
          1,
          2,
          4,
          6,
          2000,
          4,
          2,
          14000,
          3,
          2,
          4,
          3,
          4,
          6,
          5,
          4,
          1,
          14000,
        },
        Table {
          2,
          1,
          0,
          2,
          2,
          6,
          4,
          4,
          2,
          11000,
          3,
          2,
          2,
          3,
          5,
          4,
          1,
          11000,
        },
        Table {
          2,
          1,
          0,
          2,
          1,
          3,
        },
      },
      "rootID": 1,
      "snapshots": Table {},
    },
  },
  "version": 4,
}
]=]

exports[ [=[ProfilingCache should collect data for each rendered fiber: FiberCommits: element 2 1]=] ] = [=[

Table {
  1,
  2,
  3,
}
]=]

exports[ [=[ProfilingCache should collect data for each rendered fiber: FiberCommits: element 3 1]=] ] = [=[

Table {
  1,
  2,
  3,
}
]=]

exports[ [=[ProfilingCache should collect data for each rendered fiber: FiberCommits: element 4 1]=] ] = [=[

Table {
  1,
}
]=]

exports[ [=[ProfilingCache should collect data for each rendered fiber: FiberCommits: element 5 1]=] ] = [=[

Table {
  2,
  3,
}
]=]

exports[ [=[ProfilingCache should collect data for each rendered fiber: FiberCommits: element 6 1]=] ] = [=[

Table {
  3,
}
]=]

exports[ [=[ProfilingCache should collect data for each rendered fiber: imported data 1]=] ] = [=[

Table {
  "dataForRoots": Table {
    Table {
      "commitData": Table {
        Table {
          "changeDescriptions": Table {
            Table {
              2,
              Table {
                "didHooksChange": false,
                "isFirstMount": true,
              },
            },
            Table {
              3,
              Table {
                "didHooksChange": false,
                "isFirstMount": true,
              },
            },
            Table {
              4,
              Table {
                "didHooksChange": false,
                "isFirstMount": true,
              },
            },
          },
          "duration": 11,
          "fiberActualDurations": Table {
            Table {
              1,
              11,
            },
            Table {
              2,
              11,
            },
            Table {
              3,
              0,
            },
            Table {
              4,
              1,
            },
          },
          "fiberSelfDurations": Table {
            Table {
              1,
              0,
            },
            Table {
              2,
              10,
            },
            Table {
              3,
              0,
            },
            Table {
              4,
              1,
            },
          },
          "interactionIDs": Table {},
          "priorityLevel": "Normal",
          "timestamp": 11,
        },
        Table {
          "changeDescriptions": Table {
            Table {
              3,
              Table {
                "didHooksChange": false,
                "isFirstMount": false,
                "props": Table {},
              },
            },
            Table {
              5,
              Table {
                "didHooksChange": false,
                "isFirstMount": true,
              },
            },
            Table {
              2,
              Table {
                "didHooksChange": false,
                "isFirstMount": false,
                "props": Table {
                  "count",
                },
              },
            },
          },
          "duration": 11,
          "fiberActualDurations": Table {
            Table {
              3,
              0,
            },
            Table {
              5,
              1,
            },
            Table {
              2,
              11,
            },
            Table {
              1,
              11,
            },
          },
          "fiberSelfDurations": Table {
            Table {
              3,
              0,
            },
            Table {
              5,
              1,
            },
            Table {
              2,
              10,
            },
            Table {
              1,
              0,
            },
          },
          "interactionIDs": Table {},
          "priorityLevel": "Normal",
          "timestamp": 22,
        },
        Table {
          "changeDescriptions": Table {
            Table {
              3,
              Table {
                "didHooksChange": false,
                "isFirstMount": false,
                "props": Table {},
              },
            },
            Table {
              5,
              Table {
                "didHooksChange": false,
                "isFirstMount": false,
                "props": Table {},
              },
            },
            Table {
              6,
              Table {
                "didHooksChange": false,
                "isFirstMount": true,
              },
            },
            Table {
              2,
              Table {
                "didHooksChange": false,
                "isFirstMount": false,
                "props": Table {
                  "count",
                },
              },
            },
          },
          "duration": 13,
          "fiberActualDurations": Table {
            Table {
              3,
              0,
            },
            Table {
              5,
              1,
            },
            Table {
              6,
              2,
            },
            Table {
              2,
              13,
            },
            Table {
              1,
              13,
            },
          },
          "fiberSelfDurations": Table {
            Table {
              3,
              0,
            },
            Table {
              5,
              1,
            },
            Table {
              6,
              2,
            },
            Table {
              2,
              10,
            },
            Table {
              1,
              0,
            },
          },
          "interactionIDs": Table {},
          "priorityLevel": "Normal",
          "timestamp": 35,
        },
      },
      "displayName": "Parent",
      "initialTreeBaseDurations": Table {},
      "interactionCommits": Table {},
      "interactions": Table {},
      "operations": Table {
        Table {
          2,
          1,
          4,
          "Parent",
          "Child",
          "0",
          "2",
          1,
          1,
          11,
          1,
          0,
          4,
          1,
          11000,
          1,
          2,
          5,
          1,
          0,
          1,
          0,
          4,
          2,
          11000,
          1,
          3,
          5,
          2,
          2,
          2,
          3,
          4,
          3,
          0,
          1,
          4,
          8,
          2,
          2,
          2,
          4,
          4,
          4,
          1000,
        },
        Table {
          2,
          1,
          2,
          "Child",
          "1",
          1,
          5,
          5,
          2,
          2,
          1,
          2,
          4,
          5,
          1000,
          4,
          2,
          12000,
          3,
          2,
          3,
          3,
          5,
          4,
          4,
          1,
          12000,
        },
        Table {
          2,
          1,
          2,
          "Child",
          "2",
          1,
          6,
          5,
          2,
          2,
          1,
          2,
          4,
          6,
          2000,
          4,
          2,
          14000,
          3,
          2,
          4,
          3,
          5,
          6,
          4,
          4,
          1,
          14000,
        },
      },
      "rootID": 1,
      "snapshots": Table {},
    },
  },
  "version": 4,
}
]=]

exports[ [=[ProfilingCache should handle unexpectedly shallow suspense trees: Empty Suspense node 1]=] ] = [=[

Table {
  "commitData": Table {
    Table {
      "changeDescriptions": Table {
        "_array": Table {},
        "_map": Table {},
        "size": 0,
      },
      "duration": 0,
      "fiberActualDurations": Table {
        "_array": Table {
          1,
          2,
        },
        "_map": Table {
          0,
          0,
        },
        "size": 2,
      },
      "fiberSelfDurations": Table {
        "_array": Table {
          1,
          2,
        },
        "_map": Table {
          0,
          0,
        },
        "size": 2,
      },
      "interactionIDs": Table {},
      "priorityLevel": "Normal",
      "timestamp": 0,
    },
  },
  "displayName": "Suspense",
  "initialTreeBaseDurations": Table {
    "_array": Table {},
    "_map": Table {},
    "size": 0,
  },
  "interactionCommits": Table {
    "_array": Table {},
    "_map": Table {},
    "size": 0,
  },
  "interactions": Table {
    "_array": Table {},
    "_map": Table {},
    "size": 0,
  },
  "operations": Table {
    Table {
      2,
      1,
      1,
      "Suspense",
      1,
      1,
      11,
      1,
      0,
      1,
      2,
      12,
      1,
      0,
      1,
      0,
      4,
      2,
      0,
    },
  },
  "rootID": 1,
  "snapshots": Table {
    "_array": Table {},
    "_map": Table {},
    "size": 0,
  },
}
]=]

exports[ [=[ProfilingCache should properly detect changed hooks: CommitDetails commitIndex: 0 1]=] ] = [=[

Table {
  "changeDescriptions": Table {
    "_array": Table {
      3,
    },
    "_map": Table {
      3: Table {
        "didHooksChange": false,
        "isFirstMount": true,
      },
    },
    "size": 1,
  },
  "duration": 0,
  "fiberActualDurations": Table {
    "_array": Table {
      1,
      2,
      3,
    },
    "_map": Table {
      0,
      0,
      0,
    },
    "size": 3,
  },
  "fiberSelfDurations": Table {
    "_array": Table {
      1,
      2,
      3,
    },
    "_map": Table {
      0,
      0,
      0,
    },
    "size": 3,
  },
  "interactionIDs": Table {},
  "priorityLevel": "Normal",
  "timestamp": 0,
}
]=]

exports[ [=[ProfilingCache should properly detect changed hooks: CommitDetails commitIndex: 1 1]=] ] = [=[

Table {
  "changeDescriptions": Table {
    "_array": Table {
      3,
    },
    "_map": Table {
      3: Table {
        "didHooksChange": true,
        "isFirstMount": false,
        "props": Table {
          "count",
        },
      },
    },
    "size": 1,
  },
  "duration": 0,
  "fiberActualDurations": Table {
    "_array": Table {
      3,
      2,
      1,
    },
    "_map": Table {
      0,
      0,
      0,
    },
    "size": 3,
  },
  "fiberSelfDurations": Table {
    "_array": Table {
      3,
      2,
      1,
    },
    "_map": Table {
      0,
      0,
      0,
    },
    "size": 3,
  },
  "interactionIDs": Table {},
  "priorityLevel": "Normal",
  "timestamp": 0,
}
]=]

exports[ [=[ProfilingCache should properly detect changed hooks: CommitDetails commitIndex: 2 1]=] ] = [=[

Table {
  "changeDescriptions": Table {
    "_array": Table {
      3,
    },
    "_map": Table {
      3: Table {
        "didHooksChange": true,
        "isFirstMount": false,
        "props": Table {},
      },
    },
    "size": 1,
  },
  "duration": 0,
  "fiberActualDurations": Table {
    "_array": Table {
      3,
    },
    "_map": Table {
      3: 0,
    },
    "size": 1,
  },
  "fiberSelfDurations": Table {
    "_array": Table {
      3,
    },
    "_map": Table {
      3: 0,
    },
    "size": 1,
  },
  "interactionIDs": Table {},
  "priorityLevel": "Normal",
  "timestamp": 0,
}
]=]

exports[ [=[ProfilingCache should properly detect changed hooks: CommitDetails commitIndex: 3 1]=] ] = [=[

Table {
  "changeDescriptions": Table {
    "_array": Table {
      3,
    },
    "_map": Table {
      3: Table {
        "didHooksChange": true,
        "isFirstMount": false,
        "props": Table {},
      },
    },
    "size": 1,
  },
  "duration": 0,
  "fiberActualDurations": Table {
    "_array": Table {
      3,
    },
    "_map": Table {
      3: 0,
    },
    "size": 1,
  },
  "fiberSelfDurations": Table {
    "_array": Table {
      3,
    },
    "_map": Table {
      3: 0,
    },
    "size": 1,
  },
  "interactionIDs": Table {},
  "priorityLevel": "Normal",
  "timestamp": 0,
}
]=]

exports[ [=[ProfilingCache should properly detect changed hooks: CommitDetails commitIndex: 4 1]=] ] = [=[

Table {
  "changeDescriptions": Table {
    "_array": Table {
      3,
    },
    "_map": Table {
      3: Table {
        "didHooksChange": true,
        "isFirstMount": false,
        "props": Table {},
      },
    },
    "size": 1,
  },
  "duration": 0,
  "fiberActualDurations": Table {
    "_array": Table {
      3,
      2,
      1,
    },
    "_map": Table {
      0,
      0,
      0,
    },
    "size": 3,
  },
  "fiberSelfDurations": Table {
    "_array": Table {
      3,
      2,
      1,
    },
    "_map": Table {
      0,
      0,
      0,
    },
    "size": 3,
  },
  "interactionIDs": Table {},
  "priorityLevel": "Normal",
  "timestamp": 0,
}
]=]

exports[ [=[ProfilingCache should properly detect changed hooks: imported data 1]=] ] = [=[

Table {
  "dataForRoots": Table {
    Table {
      "commitData": Table {
        Table {
          "changeDescriptions": Table {
            Table {
              3,
              Table {
                "didHooksChange": false,
                "isFirstMount": true,
              },
            },
          },
          "duration": 0,
          "fiberActualDurations": Table {
            Table {
              1,
              0,
            },
            Table {
              2,
              0,
            },
            Table {
              3,
              0,
            },
          },
          "fiberSelfDurations": Table {
            Table {
              1,
              0,
            },
            Table {
              2,
              0,
            },
            Table {
              3,
              0,
            },
          },
          "interactionIDs": Table {},
          "priorityLevel": "Normal",
          "timestamp": 0,
        },
        Table {
          "changeDescriptions": Table {
            Table {
              3,
              Table {
                "didHooksChange": true,
                "isFirstMount": false,
                "props": Table {
                  "count",
                },
              },
            },
          },
          "duration": 0,
          "fiberActualDurations": Table {
            Table {
              3,
              0,
            },
            Table {
              2,
              0,
            },
            Table {
              1,
              0,
            },
          },
          "fiberSelfDurations": Table {
            Table {
              3,
              0,
            },
            Table {
              2,
              0,
            },
            Table {
              1,
              0,
            },
          },
          "interactionIDs": Table {},
          "priorityLevel": "Normal",
          "timestamp": 0,
        },
        Table {
          "changeDescriptions": Table {
            Table {
              3,
              Table {
                "didHooksChange": true,
                "isFirstMount": false,
                "props": Table {},
              },
            },
          },
          "duration": 0,
          "fiberActualDurations": Table {
            Table {
              3,
              0,
            },
          },
          "fiberSelfDurations": Table {
            Table {
              3,
              0,
            },
          },
          "interactionIDs": Table {},
          "priorityLevel": "Normal",
          "timestamp": 0,
        },
        Table {
          "changeDescriptions": Table {
            Table {
              3,
              Table {
                "didHooksChange": true,
                "isFirstMount": false,
                "props": Table {},
              },
            },
          },
          "duration": 0,
          "fiberActualDurations": Table {
            Table {
              3,
              0,
            },
          },
          "fiberSelfDurations": Table {
            Table {
              3,
              0,
            },
          },
          "interactionIDs": Table {},
          "priorityLevel": "Normal",
          "timestamp": 0,
        },
        Table {
          "changeDescriptions": Table {
            Table {
              3,
              Table {
                "didHooksChange": true,
                "isFirstMount": false,
                "props": Table {},
              },
            },
          },
          "duration": 0,
          "fiberActualDurations": Table {
            Table {
              3,
              0,
            },
            Table {
              2,
              0,
            },
            Table {
              1,
              0,
            },
          },
          "fiberSelfDurations": Table {
            Table {
              3,
              0,
            },
            Table {
              2,
              0,
            },
            Table {
              1,
              0,
            },
          },
          "interactionIDs": Table {},
          "priorityLevel": "Normal",
          "timestamp": 0,
        },
      },
      "displayName": "Component",
      "initialTreeBaseDurations": Table {},
      "interactionCommits": Table {},
      "interactions": Table {},
      "operations": Table {
        Table {
          2,
          1,
          2,
          "Context.Provider",
          "Component",
          1,
          1,
          11,
          1,
          0,
          1,
          2,
          2,
          1,
          0,
          1,
          0,
          4,
          2,
          0,
          1,
          3,
          5,
          2,
          0,
          2,
          0,
          4,
          3,
          0,
        },
        Table {
          2,
          1,
          0,
        },
        Table {
          2,
          1,
          0,
        },
        Table {
          2,
          1,
          0,
        },
        Table {
          2,
          1,
          0,
        },
      },
      "rootID": 1,
      "snapshots": Table {},
    },
  },
  "version": 4,
}
]=]

exports[ [=[ProfilingCache should record changed props/state/context/hooks: CommitDetails commitIndex: 0 1]=] ] = [=[

Table {
  "changeDescriptions": Table {
    "_array": Table {
      2,
      4,
      5,
      6,
      7,
    },
    "_map": Table {
      ,
      Table {
        "didHooksChange": false,
        "isFirstMount": true,
      },
      ,
      Table {
        "didHooksChange": false,
        "isFirstMount": true,
      },
      Table {
        "didHooksChange": false,
        "isFirstMount": true,
      },
      Table {
        "didHooksChange": false,
        "isFirstMount": true,
      },
      Table {
        "didHooksChange": false,
        "isFirstMount": true,
      },
    },
    "size": 5,
  },
  "duration": 0,
  "fiberActualDurations": Table {
    "_array": Table {
      1,
      2,
      3,
      4,
      5,
      6,
      7,
    },
    "_map": Table {
      0,
      0,
      0,
      0,
      0,
      0,
      0,
    },
    "size": 7,
  },
  "fiberSelfDurations": Table {
    "_array": Table {
      1,
      2,
      3,
      4,
      5,
      6,
      7,
    },
    "_map": Table {
      0,
      0,
      0,
      0,
      0,
      0,
      0,
    },
    "size": 7,
  },
  "interactionIDs": Table {},
  "priorityLevel": "Normal",
  "timestamp": 0,
}
]=]

exports[ [=[ProfilingCache should record changed props/state/context/hooks: CommitDetails commitIndex: 1 1]=] ] = [=[

Table {
  "changeDescriptions": Table {
    "_array": Table {
      7,
      6,
    },
    "_map": Table {
      6: Table {
        "didHooksChange": false,
        "isFirstMount": false,
        "props": Table {},
        "state": Table {
          "count",
        },
      },
      7: Table {
        "didHooksChange": false,
        "isFirstMount": false,
        "props": Table {},
        "state": Table {},
      },
    },
    "size": 2,
  },
  "duration": 0,
  "fiberActualDurations": Table {
    "_array": Table {
      7,
      6,
    },
    "_map": Table {
      6: 0,
      7: 0,
    },
    "size": 2,
  },
  "fiberSelfDurations": Table {
    "_array": Table {
      7,
      6,
    },
    "_map": Table {
      6: 0,
      7: 0,
    },
    "size": 2,
  },
  "interactionIDs": Table {},
  "priorityLevel": "Normal",
  "timestamp": 0,
}
]=]

exports[ [=[ProfilingCache should record changed props/state/context/hooks: CommitDetails commitIndex: 2 1]=] ] = [=[

Table {
  "changeDescriptions": Table {
    "_array": Table {
      5,
      4,
      7,
      6,
      2,
    },
    "_map": Table {
      ,
      Table {
        "didHooksChange": false,
        "isFirstMount": false,
        "props": Table {
          "foo",
        },
        "state": Table {},
      },
      ,
      Table {
        "didHooksChange": false,
        "isFirstMount": false,
        "props": Table {},
        "state": Table {},
      },
      Table {
        "didHooksChange": false,
        "isFirstMount": false,
        "props": Table {},
        "state": Table {},
      },
      Table {
        "didHooksChange": false,
        "isFirstMount": false,
        "props": Table {},
        "state": Table {},
      },
      Table {
        "didHooksChange": false,
        "isFirstMount": false,
        "props": Table {},
        "state": Table {},
      },
    },
    "size": 5,
  },
  "duration": 0,
  "fiberActualDurations": Table {
    "_array": Table {
      5,
      4,
      7,
      6,
      3,
      2,
      1,
    },
    "_map": Table {
      0,
      0,
      0,
      0,
      0,
      0,
      0,
    },
    "size": 7,
  },
  "fiberSelfDurations": Table {
    "_array": Table {
      5,
      4,
      7,
      6,
      3,
      2,
      1,
    },
    "_map": Table {
      0,
      0,
      0,
      0,
      0,
      0,
      0,
    },
    "size": 7,
  },
  "interactionIDs": Table {},
  "priorityLevel": "Normal",
  "timestamp": 0,
}
]=]

exports[ [=[ProfilingCache should record changed props/state/context/hooks: CommitDetails commitIndex: 3 1]=] ] = [=[

Table {
  "changeDescriptions": Table {
    "_array": Table {
      5,
      4,
      7,
      6,
      2,
    },
    "_map": Table {
      ,
      Table {
        "didHooksChange": false,
        "isFirstMount": false,
        "props": Table {
          "foo",
          "bar",
        },
        "state": Table {},
      },
      ,
      Table {
        "didHooksChange": false,
        "isFirstMount": false,
        "props": Table {},
        "state": Table {},
      },
      Table {
        "didHooksChange": false,
        "isFirstMount": false,
        "props": Table {},
        "state": Table {},
      },
      Table {
        "didHooksChange": false,
        "isFirstMount": false,
        "props": Table {},
        "state": Table {},
      },
      Table {
        "didHooksChange": false,
        "isFirstMount": false,
        "props": Table {},
        "state": Table {},
      },
    },
    "size": 5,
  },
  "duration": 0,
  "fiberActualDurations": Table {
    "_array": Table {
      5,
      4,
      7,
      6,
      3,
      2,
      1,
    },
    "_map": Table {
      0,
      0,
      0,
      0,
      0,
      0,
      0,
    },
    "size": 7,
  },
  "fiberSelfDurations": Table {
    "_array": Table {
      5,
      4,
      7,
      6,
      3,
      2,
      1,
    },
    "_map": Table {
      0,
      0,
      0,
      0,
      0,
      0,
      0,
    },
    "size": 7,
  },
  "interactionIDs": Table {},
  "priorityLevel": "Normal",
  "timestamp": 0,
}
]=]

exports[ [=[ProfilingCache should record changed props/state/context/hooks: CommitDetails commitIndex: 4 1]=] ] = [=[

Table {
  "changeDescriptions": Table {
    "_array": Table {
      5,
      4,
      7,
      6,
      2,
    },
    "_map": Table {
      ,
      Table {
        "didHooksChange": false,
        "isFirstMount": false,
        "props": Table {
          "bar",
        },
        "state": Table {},
      },
      ,
      Table {
        "didHooksChange": false,
        "isFirstMount": false,
        "props": Table {},
        "state": Table {},
      },
      Table {
        "didHooksChange": false,
        "isFirstMount": false,
        "props": Table {},
        "state": Table {},
      },
      Table {
        "didHooksChange": false,
        "isFirstMount": false,
        "props": Table {},
        "state": Table {},
      },
      Table {
        "didHooksChange": false,
        "isFirstMount": false,
        "props": Table {},
        "state": Table {},
      },
    },
    "size": 5,
  },
  "duration": 0,
  "fiberActualDurations": Table {
    "_array": Table {
      5,
      4,
      7,
      6,
      3,
      2,
      1,
    },
    "_map": Table {
      0,
      0,
      0,
      0,
      0,
      0,
      0,
    },
    "size": 7,
  },
  "fiberSelfDurations": Table {
    "_array": Table {
      5,
      4,
      7,
      6,
      3,
      2,
      1,
    },
    "_map": Table {
      0,
      0,
      0,
      0,
      0,
      0,
      0,
    },
    "size": 7,
  },
  "interactionIDs": Table {},
  "priorityLevel": "Normal",
  "timestamp": 0,
}
]=]

exports[ [=[ProfilingCache should record changed props/state/context/hooks: imported data 1]=] ] = [=[

Table {
  "dataForRoots": Table {
    Table {
      "commitData": Table {
        Table {
          "changeDescriptions": Table {
            Table {
              2,
              Table {
                "didHooksChange": false,
                "isFirstMount": true,
              },
            },
            Table {
              4,
              Table {
                "didHooksChange": false,
                "isFirstMount": true,
              },
            },
            Table {
              5,
              Table {
                "didHooksChange": false,
                "isFirstMount": true,
              },
            },
            Table {
              6,
              Table {
                "didHooksChange": false,
                "isFirstMount": true,
              },
            },
            Table {
              7,
              Table {
                "didHooksChange": false,
                "isFirstMount": true,
              },
            },
          },
          "duration": 0,
          "fiberActualDurations": Table {
            Table {
              1,
              0,
            },
            Table {
              2,
              0,
            },
            Table {
              3,
              0,
            },
            Table {
              4,
              0,
            },
            Table {
              5,
              0,
            },
            Table {
              6,
              0,
            },
            Table {
              7,
              0,
            },
          },
          "fiberSelfDurations": Table {
            Table {
              1,
              0,
            },
            Table {
              2,
              0,
            },
            Table {
              3,
              0,
            },
            Table {
              4,
              0,
            },
            Table {
              5,
              0,
            },
            Table {
              6,
              0,
            },
            Table {
              7,
              0,
            },
          },
          "interactionIDs": Table {},
          "priorityLevel": "Normal",
          "timestamp": 0,
        },
        Table {
          "changeDescriptions": Table {
            Table {
              7,
              Table {
                "didHooksChange": false,
                "isFirstMount": false,
                "props": Table {},
                "state": Table {},
              },
            },
            Table {
              6,
              Table {
                "didHooksChange": false,
                "isFirstMount": false,
                "props": Table {},
                "state": Table {
                  "count",
                },
              },
            },
          },
          "duration": 0,
          "fiberActualDurations": Table {
            Table {
              7,
              0,
            },
            Table {
              6,
              0,
            },
          },
          "fiberSelfDurations": Table {
            Table {
              7,
              0,
            },
            Table {
              6,
              0,
            },
          },
          "interactionIDs": Table {},
          "priorityLevel": "Normal",
          "timestamp": 0,
        },
        Table {
          "changeDescriptions": Table {
            Table {
              5,
              Table {
                "didHooksChange": false,
                "isFirstMount": false,
                "props": Table {},
                "state": Table {},
              },
            },
            Table {
              4,
              Table {
                "didHooksChange": false,
                "isFirstMount": false,
                "props": Table {},
                "state": Table {},
              },
            },
            Table {
              7,
              Table {
                "didHooksChange": false,
                "isFirstMount": false,
                "props": Table {},
                "state": Table {},
              },
            },
            Table {
              6,
              Table {
                "didHooksChange": false,
                "isFirstMount": false,
                "props": Table {},
                "state": Table {},
              },
            },
            Table {
              2,
              Table {
                "didHooksChange": false,
                "isFirstMount": false,
                "props": Table {
                  "foo",
                },
                "state": Table {},
              },
            },
          },
          "duration": 0,
          "fiberActualDurations": Table {
            Table {
              5,
              0,
            },
            Table {
              4,
              0,
            },
            Table {
              7,
              0,
            },
            Table {
              6,
              0,
            },
            Table {
              3,
              0,
            },
            Table {
              2,
              0,
            },
            Table {
              1,
              0,
            },
          },
          "fiberSelfDurations": Table {
            Table {
              5,
              0,
            },
            Table {
              4,
              0,
            },
            Table {
              7,
              0,
            },
            Table {
              6,
              0,
            },
            Table {
              3,
              0,
            },
            Table {
              2,
              0,
            },
            Table {
              1,
              0,
            },
          },
          "interactionIDs": Table {},
          "priorityLevel": "Normal",
          "timestamp": 0,
        },
        Table {
          "changeDescriptions": Table {
            Table {
              5,
              Table {
                "didHooksChange": false,
                "isFirstMount": false,
                "props": Table {},
                "state": Table {},
              },
            },
            Table {
              4,
              Table {
                "didHooksChange": false,
                "isFirstMount": false,
                "props": Table {},
                "state": Table {},
              },
            },
            Table {
              7,
              Table {
                "didHooksChange": false,
                "isFirstMount": false,
                "props": Table {},
                "state": Table {},
              },
            },
            Table {
              6,
              Table {
                "didHooksChange": false,
                "isFirstMount": false,
                "props": Table {},
                "state": Table {},
              },
            },
            Table {
              2,
              Table {
                "didHooksChange": false,
                "isFirstMount": false,
                "props": Table {
                  "foo",
                  "bar",
                },
                "state": Table {},
              },
            },
          },
          "duration": 0,
          "fiberActualDurations": Table {
            Table {
              5,
              0,
            },
            Table {
              4,
              0,
            },
            Table {
              7,
              0,
            },
            Table {
              6,
              0,
            },
            Table {
              3,
              0,
            },
            Table {
              2,
              0,
            },
            Table {
              1,
              0,
            },
          },
          "fiberSelfDurations": Table {
            Table {
              5,
              0,
            },
            Table {
              4,
              0,
            },
            Table {
              7,
              0,
            },
            Table {
              6,
              0,
            },
            Table {
              3,
              0,
            },
            Table {
              2,
              0,
            },
            Table {
              1,
              0,
            },
          },
          "interactionIDs": Table {},
          "priorityLevel": "Normal",
          "timestamp": 0,
        },
        Table {
          "changeDescriptions": Table {
            Table {
              5,
              Table {
                "didHooksChange": false,
                "isFirstMount": false,
                "props": Table {},
                "state": Table {},
              },
            },
            Table {
              4,
              Table {
                "didHooksChange": false,
                "isFirstMount": false,
                "props": Table {},
                "state": Table {},
              },
            },
            Table {
              7,
              Table {
                "didHooksChange": false,
                "isFirstMount": false,
                "props": Table {},
                "state": Table {},
              },
            },
            Table {
              6,
              Table {
                "didHooksChange": false,
                "isFirstMount": false,
                "props": Table {},
                "state": Table {},
              },
            },
            Table {
              2,
              Table {
                "didHooksChange": false,
                "isFirstMount": false,
                "props": Table {
                  "bar",
                },
                "state": Table {},
              },
            },
          },
          "duration": 0,
          "fiberActualDurations": Table {
            Table {
              5,
              0,
            },
            Table {
              4,
              0,
            },
            Table {
              7,
              0,
            },
            Table {
              6,
              0,
            },
            Table {
              3,
              0,
            },
            Table {
              2,
              0,
            },
            Table {
              1,
              0,
            },
          },
          "fiberSelfDurations": Table {
            Table {
              5,
              0,
            },
            Table {
              4,
              0,
            },
            Table {
              7,
              0,
            },
            Table {
              6,
              0,
            },
            Table {
              3,
              0,
            },
            Table {
              2,
              0,
            },
            Table {
              1,
              0,
            },
          },
          "interactionIDs": Table {},
          "priorityLevel": "Normal",
          "timestamp": 0,
        },
      },
      "displayName": "LegacyContextProvider",
      "initialTreeBaseDurations": Table {},
      "interactionCommits": Table {},
      "interactions": Table {},
      "operations": Table {
        Table {
          2,
          1,
          7,
          "LegacyContextProvider",
          "Context.Provider",
          "ModernContextConsumer",
          "1",
          "FunctionComponentWithHooks",
          "LegacyContextConsumer",
          "2",
          1,
          1,
          11,
          1,
          0,
          1,
          2,
          1,
          1,
          0,
          1,
          0,
          4,
          2,
          0,
          1,
          3,
          2,
          2,
          2,
          2,
          0,
          4,
          3,
          0,
          1,
          4,
          1,
          3,
          2,
          3,
          4,
          4,
          4,
          0,
          1,
          5,
          5,
          4,
          4,
          5,
          0,
          4,
          5,
          0,
          1,
          6,
          1,
          3,
          2,
          6,
          7,
          4,
          6,
          0,
          1,
          7,
          5,
          6,
          6,
          5,
          0,
          4,
          7,
          0,
        },
        Table {
          2,
          1,
          0,
        },
        Table {
          2,
          1,
          0,
        },
        Table {
          2,
          1,
          0,
        },
        Table {
          2,
          1,
          0,
        },
      },
      "rootID": 1,
      "snapshots": Table {},
    },
  },
  "version": 4,
}
]=]

return exports