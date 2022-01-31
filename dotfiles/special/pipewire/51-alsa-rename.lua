rule = {
  matches = {
    {
      {"node.name", "equals", "alsa_output.usb-C-Media_Electronics_Inc._USB_Audio_Device-00.analog-stereo"}
    }
  },
  apply_properties = {
      ["node.description"] = "USB Audio"
  }
}

table.insert(alsa_monitor.rules, rule)

rule = {
  matches = {
    {
      {"node.name", "equals", "alsa_output.pci-0000_00_1f.3.analog-stereo"}
    },
    {
      {"node.name", "equals", "alsa_input.pci-0000_00_1f.3.analog-stereo"}
    }
  },
  apply_properties = {
      ["node.description"] = "Built-in Audio"
  }
}

table.insert(alsa_monitor.rules, rule)

rule = {
  matches = {
    {
      {"node.name", "equals", "alsa_output.usb-0b0e_Jabra_Link_370_70BF927113E0-00.analog-stereo"}
    },
    {
      {"node.name", "equals", "alsa_input.usb-0b0e_Jabra_Link_370_70BF927113E0-00.mono-fallback"}
    }
  },
  apply_properties = {
      ["node.description"] = "Jabra Evolve 370 Headset"
  }
}

table.insert(alsa_monitor.rules, rule)

rule = {
    matches = {
      {
        {"node.name", "equals", "alsa_output.usb-0b0e_Jabra_SPEAK_510_USB_501AA57E1990020A00-00.analog-stereo"}
      },
      {
        {"node.name", "equals", "alsa_input.usb-0b0e_Jabra_SPEAK_510_USB_501AA57E1990020A00-00.mono-fallback"}
      }
    },
    apply_properties = {
        ["node.description"] = "Jabra Speak 510"
    }
}

table.insert(alsa_monitor.rules, rule)

rule = {
  matches = {
    {
      {"node.name", "equals", "alsa_input.usb-046d_Logitech_Webcam_C925e_9E21BDCF-02.analog-stereo"}
    }
  },
  apply_properties = {
      ["node.description"] = "Logitech C925e Webcam"
  }
}

table.insert(alsa_monitor.rules, rule)


rule = {
  matches = {
    {
      {"node.name", "equals", "alsa_output.pci-0000_01_00.1.hdmi-stereo"}
    }
  },
  apply_properties = {
      ["node.description"] = "Nvidia Graphics Audio"
  }
}

table.insert(alsa_monitor.rules, rule)

