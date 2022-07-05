window.BENCHMARK_DATA = {
  "lastUpdate": 1657038372952,
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
      },
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
          "id": "d39dd5a648ea0bf2584b97a356a8406c8d9719c0",
          "message": "Merge pull request #47 from benknoble/partition-values\n\nImprove partition with partition-values",
          "timestamp": "2022-07-05T09:20:43-07:00",
          "tree_id": "b750f3bd34f1d9b6ae8a6c0715a84642e699612a",
          "url": "https://github.com/countvajhula/qi/commit/d39dd5a648ea0bf2584b97a356a8406c8d9719c0"
        },
        "date": 1657038372394,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "AND",
            "value": 203,
            "unit": "ms"
          },
          {
            "name": "NAND",
            "value": 173,
            "unit": "ms"
          },
          {
            "name": "NOR",
            "value": 74,
            "unit": "ms"
          },
          {
            "name": "NOT",
            "value": 112,
            "unit": "ms"
          },
          {
            "name": "OR",
            "value": 44,
            "unit": "ms"
          },
          {
            "name": "XNOR",
            "value": 85,
            "unit": "ms"
          },
          {
            "name": "XOR",
            "value": 52,
            "unit": "ms"
          },
          {
            "name": "all",
            "value": 134,
            "unit": "ms"
          },
          {
            "name": "all?",
            "value": 141,
            "unit": "ms"
          },
          {
            "name": "amp",
            "value": 247,
            "unit": "ms"
          },
          {
            "name": "and",
            "value": 135,
            "unit": "ms"
          },
          {
            "name": "and%",
            "value": 201,
            "unit": "ms"
          },
          {
            "name": "any",
            "value": 124,
            "unit": "ms"
          },
          {
            "name": "any?",
            "value": 43,
            "unit": "ms"
          },
          {
            "name": "apply",
            "value": 129,
            "unit": "ms"
          },
          {
            "name": "block",
            "value": 658,
            "unit": "ms"
          },
          {
            "name": "bundle",
            "value": 678,
            "unit": "ms"
          },
          {
            "name": "catchall-template",
            "value": 212,
            "unit": "ms"
          },
          {
            "name": "clos",
            "value": 196,
            "unit": "ms"
          },
          {
            "name": "collect",
            "value": 172,
            "unit": "ms"
          },
          {
            "name": "count",
            "value": 181,
            "unit": "ms"
          },
          {
            "name": "crossover",
            "value": 126,
            "unit": "ms"
          },
          {
            "name": "currying",
            "value": 128,
            "unit": "ms"
          },
          {
            "name": "effect",
            "value": 99,
            "unit": "ms"
          },
          {
            "name": "esc",
            "value": 172,
            "unit": "ms"
          },
          {
            "name": "fanout",
            "value": 256,
            "unit": "ms"
          },
          {
            "name": "feedback",
            "value": 202,
            "unit": "ms"
          },
          {
            "name": ">>",
            "value": 165,
            "unit": "ms"
          },
          {
            "name": "<<",
            "value": 180,
            "unit": "ms"
          },
          {
            "name": "gate",
            "value": 130,
            "unit": "ms"
          },
          {
            "name": "gen",
            "value": 163,
            "unit": "ms"
          },
          {
            "name": "ground",
            "value": 35,
            "unit": "ms"
          },
          {
            "name": "group",
            "value": 233,
            "unit": "ms"
          },
          {
            "name": "if",
            "value": 129,
            "unit": "ms"
          },
          {
            "name": "input aliases",
            "value": 73,
            "unit": "ms"
          },
          {
            "name": "inverter",
            "value": 163,
            "unit": "ms"
          },
          {
            "name": "live?",
            "value": 86,
            "unit": "ms"
          },
          {
            "name": "loop",
            "value": 329,
            "unit": "ms"
          },
          {
            "name": "loop2",
            "value": 1666,
            "unit": "ms"
          },
          {
            "name": "none",
            "value": 167,
            "unit": "ms"
          },
          {
            "name": "none?",
            "value": 60,
            "unit": "ms"
          },
          {
            "name": "not",
            "value": 124,
            "unit": "ms"
          },
          {
            "name": "one-of?",
            "value": 122,
            "unit": "ms"
          },
          {
            "name": "or",
            "value": 134,
            "unit": "ms"
          },
          {
            "name": "or%",
            "value": 187,
            "unit": "ms"
          },
          {
            "name": "partition",
            "value": 290,
            "unit": "ms"
          },
          {
            "name": "pass",
            "value": 159,
            "unit": "ms"
          },
          {
            "name": "rectify",
            "value": 116,
            "unit": "ms"
          },
          {
            "name": "relay",
            "value": 184,
            "unit": "ms"
          },
          {
            "name": "relay*",
            "value": 70,
            "unit": "ms"
          },
          {
            "name": "select",
            "value": 7,
            "unit": "ms"
          },
          {
            "name": "sep",
            "value": 209,
            "unit": "ms"
          },
          {
            "name": "sieve",
            "value": 204,
            "unit": "ms"
          },
          {
            "name": "switch",
            "value": 251,
            "unit": "ms"
          },
          {
            "name": "tee",
            "value": 130,
            "unit": "ms"
          },
          {
            "name": "template",
            "value": 39,
            "unit": "ms"
          },
          {
            "name": "thread",
            "value": 303,
            "unit": "ms"
          },
          {
            "name": "thread-right",
            "value": 298,
            "unit": "ms"
          },
          {
            "name": "try",
            "value": 182,
            "unit": "ms"
          },
          {
            "name": "unless",
            "value": 139,
            "unit": "ms"
          },
          {
            "name": "when",
            "value": 130,
            "unit": "ms"
          }
        ]
      }
    ]
  }
}