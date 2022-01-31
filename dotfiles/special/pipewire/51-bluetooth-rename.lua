rule = {
  matches = {
    {
      { "node.name", "equals", "bluez_output.38_18_4C_06_88_22.a2dp-sink" },
    },
  },
  apply_properties = {
    ["node.description"] = "Sony WH-1000XM3 Headphones",
  },
}

table.insert(bluez_monitor.rules,rule)
