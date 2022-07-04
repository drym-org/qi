window.BENCHMARK_DATA = {
  "lastUpdate": 1656972262416,
  "repoUrl": "https://github.com/countvajhula/qi",
  "entries": {
    "Qi Forms Benchmarks": [
      {
        "commit": {
          "author": {
            "email": "sid@countvajhula.com",
            "name": "Siddhartha Kasivajhula",
            "username": "countvajhula"
          },
          "committer": {
            "email": "noreply@github.com",
            "name": "GitHub",
            "username": "web-flow"
          },
          "distinct": true,
          "id": "8510bea032a7b6c6835d794fe438f03a63a8df52",
          "message": "Merge pull request #46 from benknoble/partition-naïve\n\nImplement partition naïvely",
          "timestamp": "2022-07-04T14:58:09-07:00",
          "tree_id": "c6976939f39adb5581c6fc0205f8fc2e6a2d8db0",
          "url": "https://github.com/countvajhula/qi/commit/8510bea032a7b6c6835d794fe438f03a63a8df52"
        },
        "date": 1656972261684,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "AND",
            "value": 227,
            "unit": "ms"
          },
          {
            "name": "NAND",
            "value": 182,
            "unit": "ms"
          },
          {
            "name": "NOR",
            "value": 77,
            "unit": "ms"
          },
          {
            "name": "NOT",
            "value": 111,
            "unit": "ms"
          },
          {
            "name": "OR",
            "value": 47,
            "unit": "ms"
          },
          {
            "name": "XNOR",
            "value": 89,
            "unit": "ms"
          },
          {
            "name": "XOR",
            "value": 61,
            "unit": "ms"
          },
          {
            "name": "all",
            "value": 149,
            "unit": "ms"
          },
          {
            "name": "all?",
            "value": 148,
            "unit": "ms"
          },
          {
            "name": "amp",
            "value": 267,
            "unit": "ms"
          },
          {
            "name": "and",
            "value": 132,
            "unit": "ms"
          },
          {
            "name": "and%",
            "value": 194,
            "unit": "ms"
          },
          {
            "name": "any",
            "value": 145,
            "unit": "ms"
          },
          {
            "name": "any?",
            "value": 46,
            "unit": "ms"
          },
          {
            "name": "apply",
            "value": 136,
            "unit": "ms"
          },
          {
            "name": "block",
            "value": 671,
            "unit": "ms"
          },
          {
            "name": "bundle",
            "value": 690,
            "unit": "ms"
          },
          {
            "name": "catchall-template",
            "value": 215,
            "unit": "ms"
          },
          {
            "name": "clos",
            "value": 205,
            "unit": "ms"
          },
          {
            "name": "collect",
            "value": 190,
            "unit": "ms"
          },
          {
            "name": "count",
            "value": 196,
            "unit": "ms"
          },
          {
            "name": "crossover",
            "value": 140,
            "unit": "ms"
          },
          {
            "name": "currying",
            "value": 131,
            "unit": "ms"
          },
          {
            "name": "effect",
            "value": 105,
            "unit": "ms"
          },
          {
            "name": "esc",
            "value": 186,
            "unit": "ms"
          },
          {
            "name": "fanout",
            "value": 215,
            "unit": "ms"
          },
          {
            "name": "feedback",
            "value": 218,
            "unit": "ms"
          },
          {
            "name": ">>",
            "value": 167,
            "unit": "ms"
          },
          {
            "name": "<<",
            "value": 187,
            "unit": "ms"
          },
          {
            "name": "gate",
            "value": 146,
            "unit": "ms"
          },
          {
            "name": "gen",
            "value": 191,
            "unit": "ms"
          },
          {
            "name": "ground",
            "value": 37,
            "unit": "ms"
          },
          {
            "name": "group",
            "value": 251,
            "unit": "ms"
          },
          {
            "name": "if",
            "value": 140,
            "unit": "ms"
          },
          {
            "name": "input aliases",
            "value": 76,
            "unit": "ms"
          },
          {
            "name": "inverter",
            "value": 174,
            "unit": "ms"
          },
          {
            "name": "live?",
            "value": 95,
            "unit": "ms"
          },
          {
            "name": "loop",
            "value": 360,
            "unit": "ms"
          },
          {
            "name": "loop2",
            "value": 1669,
            "unit": "ms"
          },
          {
            "name": "none",
            "value": 193,
            "unit": "ms"
          },
          {
            "name": "none?",
            "value": 65,
            "unit": "ms"
          },
          {
            "name": "not",
            "value": 118,
            "unit": "ms"
          },
          {
            "name": "one-of?",
            "value": 129,
            "unit": "ms"
          },
          {
            "name": "or",
            "value": 133,
            "unit": "ms"
          },
          {
            "name": "or%",
            "value": 183,
            "unit": "ms"
          },
          {
            "name": "partition",
            "value": 517,
            "unit": "ms"
          },
          {
            "name": "pass",
            "value": 171,
            "unit": "ms"
          },
          {
            "name": "rectify",
            "value": 123,
            "unit": "ms"
          },
          {
            "name": "relay",
            "value": 189,
            "unit": "ms"
          },
          {
            "name": "relay*",
            "value": 68,
            "unit": "ms"
          },
          {
            "name": "select",
            "value": 8,
            "unit": "ms"
          },
          {
            "name": "sep",
            "value": 250,
            "unit": "ms"
          },
          {
            "name": "sieve",
            "value": 222,
            "unit": "ms"
          },
          {
            "name": "switch",
            "value": 271,
            "unit": "ms"
          },
          {
            "name": "tee",
            "value": 130,
            "unit": "ms"
          },
          {
            "name": "template",
            "value": 42,
            "unit": "ms"
          },
          {
            "name": "thread",
            "value": 318,
            "unit": "ms"
          },
          {
            "name": "thread-right",
            "value": 309,
            "unit": "ms"
          },
          {
            "name": "try",
            "value": 202,
            "unit": "ms"
          },
          {
            "name": "unless",
            "value": 143,
            "unit": "ms"
          },
          {
            "name": "when",
            "value": 139,
            "unit": "ms"
          }
        ]
      }
    ]
  }
}