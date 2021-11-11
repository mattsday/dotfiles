alsa_monitor.rules = {
  {
    matches = {
      {
        -- USB Audio Device (for KVM switching) - always prefer this
        { "node.name", "matches", "alsa_output.usb-C-Media_Electronics_Inc._USB_Audio_Device-00.playback.0.0" },
      },
    },
    apply_properties = {
      ["device.nick"] = "USB Audio",
      ["node.description"] = "USB Audio",
      ["priority.session"] = 2010
    },
  },
  {
    matches = {
      {
        -- USB Audio Device (for KVM switching) - always prefer this
        { "node.name", "matches", "alsa_input.usb-C-Media_Electronics_Inc._USB_Audio_Device-00.capture.0.0" },
      },
    },
    apply_properties = {
      ["device.nick"] = "USB Audio",
      ["node.description"] = "USB Audio",
      ["priority.session"] = 0
    },
  },
  {
    matches = {
      {
        -- Built-in Audio, high priority for regular output
        { "node.name", "matches", "alsa_output.pci-0000_00_1f.3.analog-stereo" },
        { "node.name", "matches", "alsa_input.pci-0000_00_1f.3.analog-stereo" },
      },
    },
    apply_properties = {
      ["device.nick"] = "Built-in Audio",
      ["node.description"] = "Built-in Audio",
      ["priority.session"] = 2005
    },
  },
  {
    matches = {
      {
        -- Jabra 370 Headset - High Capture priority
        { "node.name", "matches", "alsa_input.usb-0b0e_Jabra_Link_370_70BF927113E0-00.mono-fallback" },
      },
    },
    apply_properties = {
      ["priority.session"] = 2000
    },
  },
  {
    matches = {
      {
        -- Jabra 370 Headset - Lower Playback priority
        { "node.name", "matches", "alsa_output.usb-0b0e_Jabra_Link_370_70BF927113E0-00.analog-stereo" },
      },
    },
    apply_properties = {
      ["priority.session"] = 1500
    },
  },
  {
    matches = {
      {
        -- Jabra 370 Headset - rename device
        { "node.name", "matches", "alsa_output.usb-0b0e_Jabra_Link_370_70BF927113E0-00.analog-stereo" },
        { "node.name", "matches", "alsa_input.usb-0b0e_Jabra_Link_370_70BF927113E0-00.mono-fallback" },
      },
    },
    apply_properties = {
      ["device.nick"] = "Jabra Evolve 370 Headset",
      ["node.description"] = "Jabra Evolve 370 Headset"
    },
  },
  {
    matches = {
      {
        -- Jabra 510 speaker - medium priority and rename
        { "node.name", "matches", "alsa_output.usb-0b0e_Jabra_SPEAK_510_USB_501AA57E1990020A00-00.analog-stereo" },
        { "node.name", "matches", "alsa_input.usb-0b0e_Jabra_SPEAK_510_USB_501AA57E1990020A00-00.mono-fallback" },
      },
    },
    apply_properties = {
      ["device.nick"] = "Jabra Speak 510",
      ["node.description"] = "Jabra Speak 510",
      ["priority.session"] = 1900

    },
  },
}
