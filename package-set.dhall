let upstream = https://github.com/dfinity/vessel-package-set/releases/download/mo-0.9.1-20230516/package-set.dhall sha256:1ec31bbdea0234767f35941608d4c763b9dd9951858158057fa92a4a71b574d6

let packages = [
  { name = "stable-rbtree"
  , repo = "https://github.com/canscale/StableRBTree"
  , version = "v0.6.0"
  , dependencies = [ "base" ]
  },
  { name = "stable-buffer"
  , repo = "https://github.com/canscale/StableBuffer"
  , version = "v0.2.0"
  , dependencies = [ "base" ]
  },
  { name = "candb"
  , repo = "https://github.com/canscale/CanDB"
  , version = "beta"
  , dependencies = [ "base" ]
  },
  { name = "btree"
  , repo = "https://github.com/canscale/StableHeapBTreeMap"
  , version = "v0.3.1"
  , dependencies = [ "base" ]
  },

  { name = "lexicographic-encoding"
  , repo = "https://github.com/canscale/lexicographic-encoding"
  , version = "0.1.0"
  , dependencies = [ "base", "hex" ]
  },
  { name = "hex"
  , repo = "https://github.com/ByronBecker/motoko-hex"
  , version = "main"
  , dependencies = [ "base" ]
  },

  { name = "base-0.7.3"
  , repo = "https://github.com/dfinity/motoko-base"
  , version = "moc-0.7.3"
  , dependencies = [ "base-0.7.3" ]
  },
  { name = "json"
  , repo = "https://github.com/aviate-labs/json.mo"
  , version = "main"
  , dependencies = [ "base-0.7.3", "parser-combinators" ]
  },
  { name = "parser-combinators"
  , repo = "https://github.com/aviate-labs/parser-combinators.mo"
  , version = "v0.1.2"
  , dependencies = [ "base-0.7.3" ]
  },
  { name = "DateTime"
  , repo = "https://github.com/byronbecker/motoko-datetime"
  , version = "v0.1.1"
  , dependencies = [ "base" ]
  }
]

in  upstream # packages
