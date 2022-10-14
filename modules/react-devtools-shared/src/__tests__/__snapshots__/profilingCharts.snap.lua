-- Jest Roblox Snapshot v1, http://roblox.github.io/jest-roblox/snapshot-testing

local exports = {}

exports[ [=[profiling charts flamegraph chart should contain valid data: 0: CommitTree 1]=] ] = [=[

Table {
  "nodes": Table {
    "_array": Table {
      1,
      2,
      3,
      4,
      5,
    },
    "_map": Table {
      Table {
        "children": Table {
          2,
        },
        "id": 1,
        "parentID": 0,
        "treeBaseDuration": 15,
        "type": 11,
      },
      Table {
        "children": Table {
          3,
          4,
          5,
        },
        "displayName": "Parent",
        "id": 2,
        "key": "",
        "parentID": 1,
        "treeBaseDuration": 15,
        "type": 5,
      },
      Table {
        "children": Table {},
        "displayName": "Child",
        "id": 3,
        "key": "first",
        "parentID": 2,
        "treeBaseDuration": 3,
        "type": 8,
      },
      Table {
        "children": Table {},
        "displayName": "Child",
        "id": 4,
        "key": "second",
        "parentID": 2,
        "treeBaseDuration": 2,
        "type": 8,
      },
      Table {
        "children": Table {},
        "displayName": "Child",
        "id": 5,
        "key": "third",
        "parentID": 2,
        "treeBaseDuration": 0,
        "type": 8,
      },
    },
    "size": 5,
  },
  "rootID": 1,
}
]=]

exports[ [=[profiling charts flamegraph chart should contain valid data: 0: FlamegraphChartData 1]=] ] = [=[

Table {
  "baseDuration": 15,
  "depth": 2,
  "idToDepthMap": Table {
    "_array": Table {
      2,
      5,
      4,
      3,
    },
    "_map": Table {
      2: 2,
      3: 2,
      4: 2,
      5: 2,
    },
    "size": 4,
  },
  "maxSelfDuration": 10,
  "renderPathNodes": Table {
    "_array": Table {
      1,
      2,
    },
    "_map": Table {
      true,
      true,
    },
    "size": 2,
  },
  "rows": Table {
    Table {
      Table {
        "actualDuration": 15,
        "didRender": true,
        "id": 2,
        "label": "Parent (10ms of 15ms)",
        "name": "Parent",
        "offset": 0,
        "selfDuration": 10,
        "treeBaseDuration": 15,
      },
      Table {
        "actualDuration": 2,
        "didRender": true,
        "id": 4,
        "label": "Child key=\"second\" (2ms of 2ms)",
        "name": "Child",
        "offset": 13,
        "selfDuration": 2,
        "treeBaseDuration": 2,
      },
      Table {
        "actualDuration": 3,
        "didRender": true,
        "id": 3,
        "label": "Child key=\"first\" (3ms of 3ms)",
        "name": "Child",
        "offset": 10,
        "selfDuration": 3,
        "treeBaseDuration": 3,
      },
    },
    Table {
      Table {
        "actualDuration": 0,
        "didRender": true,
        "id": 5,
        "label": "Child key=\"third\" (<0.1ms of <0.1ms)",
        "name": "Child",
        "offset": 15,
        "selfDuration": 0,
        "treeBaseDuration": 0,
      },
    },
  },
}
]=]

exports[ [=[profiling charts flamegraph chart should contain valid data: 1: CommitTree 1]=] ] = [=[

Table {
  "nodes": Table {
    "_array": Table {
      1,
      2,
      3,
      4,
      5,
    },
    "_map": Table {
      Table {
        "children": Table {
          2,
        },
        "id": 1,
        "parentID": 0,
        "treeBaseDuration": 15,
        "type": 11,
      },
      Table {
        "children": Table {
          3,
          4,
          5,
        },
        "displayName": "Parent",
        "id": 2,
        "key": "",
        "parentID": 1,
        "treeBaseDuration": 15,
        "type": 5,
      },
      Table {
        "children": Table {},
        "displayName": "Child",
        "id": 3,
        "key": "first",
        "parentID": 2,
        "treeBaseDuration": 3,
        "type": 8,
      },
      Table {
        "children": Table {},
        "displayName": "Child",
        "id": 4,
        "key": "second",
        "parentID": 2,
        "treeBaseDuration": 2,
        "type": 8,
      },
      Table {
        "children": Table {},
        "displayName": "Child",
        "id": 5,
        "key": "third",
        "parentID": 2,
        "treeBaseDuration": 0,
        "type": 8,
      },
    },
    "size": 5,
  },
  "rootID": 1,
}
]=]

exports[ [=[profiling charts flamegraph chart should contain valid data: 1: FlamegraphChartData 1]=] ] = [=[

Table {
  "baseDuration": 15,
  "depth": 2,
  "idToDepthMap": Table {
    "_array": Table {
      2,
      5,
      4,
      3,
    },
    "_map": Table {
      2: 2,
      3: 2,
      4: 2,
      5: 2,
    },
    "size": 4,
  },
  "maxSelfDuration": 10,
  "renderPathNodes": Table {
    "_array": Table {
      1,
    },
    "_map": Table {
      true,
    },
    "size": 1,
  },
  "rows": Table {
    Table {
      Table {
        "actualDuration": 10,
        "didRender": true,
        "id": 2,
        "label": "Parent (10ms of 10ms)",
        "name": "Parent",
        "offset": 0,
        "selfDuration": 10,
        "treeBaseDuration": 15,
      },
      Table {
        "actualDuration": 0,
        "didRender": false,
        "id": 4,
        "label": "Child key=\"second\"",
        "name": "Child",
        "offset": 13,
        "selfDuration": 0,
        "treeBaseDuration": 2,
      },
      Table {
        "actualDuration": 0,
        "didRender": false,
        "id": 3,
        "label": "Child key=\"first\"",
        "name": "Child",
        "offset": 10,
        "selfDuration": 0,
        "treeBaseDuration": 3,
      },
    },
    Table {
      Table {
        "actualDuration": 0,
        "didRender": false,
        "id": 5,
        "label": "Child key=\"third\"",
        "name": "Child",
        "offset": 15,
        "selfDuration": 0,
        "treeBaseDuration": 0,
      },
    },
  },
}
]=]

exports[ [=[profiling charts interactions should contain valid data: Interactions 1]=] ] = [=[

Table {
  "interactions": Table {
    Table {
      "__count": 0,
      "id": 0,
      "name": "mount",
      "timestamp": 0,
    },
    Table {
      "__count": 0,
      "id": 1,
      "name": "update",
      "timestamp": 15,
    },
  },
  "lastInteractionTime": 25,
  "maxCommitDuration": 15,
}
]=]

exports[ [=[profiling charts interactions should contain valid data: Interactions 2]=] ] = [=[

Table {
  "interactions": Table {
    Table {
      "__count": 0,
      "id": 0,
      "name": "mount",
      "timestamp": 0,
    },
    Table {
      "__count": 0,
      "id": 1,
      "name": "update",
      "timestamp": 15,
    },
  },
  "lastInteractionTime": 25,
  "maxCommitDuration": 15,
}
]=]

exports[ [=[profiling charts ranked chart should contain valid data: 0: CommitTree 1]=] ] = [=[

Table {
  "nodes": Table {
    "_array": Table {
      1,
      2,
      3,
      4,
      5,
    },
    "_map": Table {
      Table {
        "children": Table {
          2,
        },
        "id": 1,
        "parentID": 0,
        "treeBaseDuration": 15,
        "type": 11,
      },
      Table {
        "children": Table {
          3,
          4,
          5,
        },
        "displayName": "Parent",
        "id": 2,
        "key": "",
        "parentID": 1,
        "treeBaseDuration": 15,
        "type": 5,
      },
      Table {
        "children": Table {},
        "displayName": "Child",
        "id": 3,
        "key": "first",
        "parentID": 2,
        "treeBaseDuration": 3,
        "type": 8,
      },
      Table {
        "children": Table {},
        "displayName": "Child",
        "id": 4,
        "key": "second",
        "parentID": 2,
        "treeBaseDuration": 2,
        "type": 8,
      },
      Table {
        "children": Table {},
        "displayName": "Child",
        "id": 5,
        "key": "third",
        "parentID": 2,
        "treeBaseDuration": 0,
        "type": 8,
      },
    },
    "size": 5,
  },
  "rootID": 1,
}
]=]

exports[ [=[profiling charts ranked chart should contain valid data: 0: RankedChartData 1]=] ] = [=[

Table {
  "maxValue": 10,
  "nodes": Table {
    Table {
      "id": 2,
      "label": "Parent (10ms)",
      "name": "Parent",
      "value": 10,
    },
    Table {
      "id": 3,
      "label": "Child (Memo) key=\"first\" (3ms)",
      "name": "Child",
      "value": 3,
    },
    Table {
      "id": 4,
      "label": "Child (Memo) key=\"second\" (2ms)",
      "name": "Child",
      "value": 2,
    },
    Table {
      "id": 5,
      "label": "Child (Memo) key=\"third\" (<0.1ms)",
      "name": "Child",
      "value": 0,
    },
  },
}
]=]

exports[ [=[profiling charts ranked chart should contain valid data: 1: CommitTree 1]=] ] = [=[

Table {
  "nodes": Table {
    "_array": Table {
      1,
      2,
      3,
      4,
      5,
    },
    "_map": Table {
      Table {
        "children": Table {
          2,
        },
        "id": 1,
        "parentID": 0,
        "treeBaseDuration": 15,
        "type": 11,
      },
      Table {
        "children": Table {
          3,
          4,
          5,
        },
        "displayName": "Parent",
        "id": 2,
        "key": "",
        "parentID": 1,
        "treeBaseDuration": 15,
        "type": 5,
      },
      Table {
        "children": Table {},
        "displayName": "Child",
        "id": 3,
        "key": "first",
        "parentID": 2,
        "treeBaseDuration": 3,
        "type": 8,
      },
      Table {
        "children": Table {},
        "displayName": "Child",
        "id": 4,
        "key": "second",
        "parentID": 2,
        "treeBaseDuration": 2,
        "type": 8,
      },
      Table {
        "children": Table {},
        "displayName": "Child",
        "id": 5,
        "key": "third",
        "parentID": 2,
        "treeBaseDuration": 0,
        "type": 8,
      },
    },
    "size": 5,
  },
  "rootID": 1,
}
]=]

exports[ [=[profiling charts ranked chart should contain valid data: 1: RankedChartData 1]=] ] = [=[

Table {
  "maxValue": 10,
  "nodes": Table {
    Table {
      "id": 2,
      "label": "Parent (10ms)",
      "name": "Parent",
      "value": 10,
    },
  },
}
]=]

return exports