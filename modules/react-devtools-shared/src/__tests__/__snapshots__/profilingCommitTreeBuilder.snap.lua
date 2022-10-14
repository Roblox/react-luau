-- Jest Roblox Snapshot v1, http://roblox.github.io/jest-roblox/snapshot-testing

local exports = {}

exports[ [=[commit tree should be able to rebuild the store tree for each commit: 0: CommitTree 1]=] ] = [=[

Table {
  "nodes": Table {
    "_array": Table {
      1,
      2,
      3,
    },
    "_map": Table {
      Table {
        "children": Table {
          2,
        },
        "id": 1,
        "parentID": 0,
        "treeBaseDuration": 12,
        "type": 11,
      },
      Table {
        "children": Table {
          3,
        },
        "displayName": "Parent",
        "id": 2,
        "key": "",
        "parentID": 1,
        "treeBaseDuration": 12,
        "type": 5,
      },
      Table {
        "children": Table {},
        "displayName": "Child",
        "id": 3,
        "key": "0",
        "parentID": 2,
        "treeBaseDuration": 2,
        "type": 8,
      },
    },
    "size": 3,
  },
  "rootID": 1,
}
]=]

exports[ [=[commit tree should be able to rebuild the store tree for each commit: 1: CommitTree 1]=] ] = [=[

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
        "treeBaseDuration": 16,
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
        "treeBaseDuration": 16,
        "type": 5,
      },
      Table {
        "children": Table {},
        "displayName": "Child",
        "id": 3,
        "key": "0",
        "parentID": 2,
        "treeBaseDuration": 2,
        "type": 8,
      },
      Table {
        "children": Table {},
        "displayName": "Child",
        "id": 4,
        "key": "1",
        "parentID": 2,
        "treeBaseDuration": 2,
        "type": 8,
      },
      Table {
        "children": Table {},
        "displayName": "Child",
        "id": 5,
        "key": "2",
        "parentID": 2,
        "treeBaseDuration": 2,
        "type": 8,
      },
    },
    "size": 5,
  },
  "rootID": 1,
}
]=]

exports[ [=[commit tree should be able to rebuild the store tree for each commit: 2: CommitTree 1]=] ] = [=[

Table {
  "nodes": Table {
    "_array": Table {
      1,
      2,
      3,
      4,
    },
    "_map": Table {
      Table {
        "children": Table {
          2,
        },
        "id": 1,
        "parentID": 0,
        "treeBaseDuration": 14,
        "type": 11,
      },
      Table {
        "children": Table {
          3,
          4,
        },
        "displayName": "Parent",
        "id": 2,
        "key": "",
        "parentID": 1,
        "treeBaseDuration": 14,
        "type": 5,
      },
      Table {
        "children": Table {},
        "displayName": "Child",
        "id": 3,
        "key": "0",
        "parentID": 2,
        "treeBaseDuration": 2,
        "type": 8,
      },
      Table {
        "children": Table {},
        "displayName": "Child",
        "id": 4,
        "key": "1",
        "parentID": 2,
        "treeBaseDuration": 2,
        "type": 8,
      },
    },
    "size": 4,
  },
  "rootID": 1,
}
]=]

exports[ [=[commit tree should be able to rebuild the store tree for each commit: 3: CommitTree 1]=] ] = [=[

Table {
  "nodes": Table {
    "_array": Table {
      1,
      2,
    },
    "_map": Table {
      Table {
        "children": Table {
          2,
        },
        "id": 1,
        "parentID": 0,
        "treeBaseDuration": 10,
        "type": 11,
      },
      Table {
        "children": Table {},
        "displayName": "Parent",
        "id": 2,
        "key": "",
        "parentID": 1,
        "treeBaseDuration": 10,
        "type": 5,
      },
    },
    "size": 2,
  },
  "rootID": 1,
}
]=]

return exports