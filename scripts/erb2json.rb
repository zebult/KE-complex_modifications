#!/usr/bin/env ruby

require 'erb'
require 'json'

def block(key_code, mode_name, key, as_json=true)
    data = {}
    data['type'] = "basic"
    data['from'] = {"key_code": key, "modifiers": {"optional": ["any"]}}
    data['to'] = [{"key_code": key_code}, {"key_code": key}, {"key_code": "vk_none"}]
    data['conditions'] = [{"type": "variable_if", "name": mode_name, "value": 1}]
    make_data(data, as_json)
end

def deepcopy(data)
  Marshal.load(Marshal.dump(data))
end

def to_array(data)
  unless data.is_a? Array
    data = [data]
  end
  data
end

def make_data(data, as_json=true)
  if as_json
    JSON.generate(data)
  else
    data
  end
end

def key(data, key)
  if key == "any"
    data['any'] = "key_code"
  elsif key.start_with? "button"
    data['pointing_button'] = key
  else
    data['key_code'] = key
  end
end

def from(key_code, mandatory_modifiers=[], optional_modifiers=[], as_json=true)
  mandatory_modifiers = to_array(mandatory_modifiers)
  optional_modifiers = to_array(optional_modifiers)

  data = {}
  key(data, key_code)
  mandatory_modifiers.each do |m|
    data['modifiers'] = {} if data['modifiers'].nil?
    data['modifiers']['mandatory'] = [] if data['modifiers']['mandatory'].nil?
    data['modifiers']['mandatory'] << m
  end
  optional_modifiers.each do |m|
    data['modifiers'] = {} if data['modifiers'].nil?
    data['modifiers']['optional'] = [] if data['modifiers']['optional'].nil?
    data['modifiers']['optional'] << m
  end
  make_data(data, as_json)
end

def hash_from(key_code, mandatory_modifiers=[], optional_modifiers=[])
  from(key_code, mandatory_modifiers, optional_modifiers, false)
end

def to(events, as_json=true, repeat=1)
  data = []
  events.each do |e|
    d = {}
    if e.is_a? Array
      key(d, e[0])
      unless e[1].nil?
        d['modifiers'] = e[1]
      end
    elsif e.is_a? String
      key(d, e)
    else
      d = deepcopy(e)
    end
    data << d
  end
  data_total = []
  repeat.times do |i|
    data_total += data
  end
  make_data(data_total, as_json)
end

def hash_to(events, repeat=1)
  to(events, false, repeat)
end

def each_key(source_keys_list: :source_keys_list, dest_keys_list: :dest_keys_list, from_mandatory_modifiers: [], from_optional_modifiers: [], to_pre_events: [], to_modifiers: [], to_post_events: [], to_if_alone: [], to_after_key_up: [], conditions: [], as_json: false)
  unless source_keys_list.is_a? Array
    source_keys_list = [source_keys_list]
    dest_keys_list = [dest_keys_list]
    to_if_alone = [to_array(to_if_alone)]
  end
  data = []
  source_keys_list.each_with_index do |from_key, index|
    to_key = dest_keys_list[index]
    d = {}
    d['type'] = 'basic'
    if from_key.is_a? String
      d['from'] = from(from_key, from_mandatory_modifiers, from_optional_modifiers, false)
    else
      d['from'] = from_key
    end

    # Compile list of events to add to "to" section
    events = []
    to_pre_events.each do |e|
      events << e
    end
    if to_key.is_a? String
      if to_modifiers[0].nil?
        events << [to_key]
      else
        events << [to_key, to_modifiers]
      end
    elsif to_key.is_a? Array
      to_key.each do |e|
        events << e
      end
    else
      events << to_key
    end
    to_post_events.each do |e|
      events << e
    end
    d['to'] = hash_to(events)
    d['to_if_alone'] = to_if_alone[index] if (to_if_alone[index] and to_if_alone[index].size != 0)
    d['to_after_key_up'] = to_after_key_up unless to_after_key_up.size == 0

    if conditions.any?
      d['conditions'] = []
      conditions.each do |c|
        d['conditions'] << c
      end
    end
    data << d
  end

  make_data(data, as_json)
end

def frontmost_application(type, app_aliases, as_json=true)
  finder_bundle_identifiers = [
    '^com\.apple\.finder$',
  ]

  preview_bundle_identifiers = [
    '^com\.apple\.Preview$',
  ]

  safari_bundle_identifiers = [
    '^com\.apple\.Safari$',
  ]

  browser_bundle_identifiers = [
    '^org\.mozilla\.firefox$',
    '^org\.waterfoxproject\.waterfox$',
    '^com\.google\.Chrome$'
  ]

  emacs_bundle_identifiers = [
    '^org\.gnu\.Emacs$',
    '^org\.gnu\.AquamacsEmacs$',
    '^org\.gnu\.Aquamacs$',
    '^org\.pqrs\.unknownapp.conkeror$',
  ]

  remote_desktop_bundle_identifiers = [
    '^com\.microsoft\.rdc$',
    '^com\.microsoft\.rdc\.mac$',
    '^com\.microsoft\.rdc\.osx\.beta$',
    '^net\.sf\.cord$',
    '^com\.thinomenon\.RemoteDesktopConnection$',
    '^com\.itap-mobile\.qmote$',
    '^com\.nulana\.remotixmac$',
    '^com\.p5sys\.jump\.mac\.viewer$',
    '^com\.p5sys\.jump\.mac\.viewer\.web$',
    '^com\.vmware\.horizon$',
    '^com\.2X\.Client\.Mac$',
  ]

  iterm2_bundle_identifiers = [
    '^com\.googlecode\.iterm2$',
  ]

  terminal_bundle_identifiers = iterm2_bundle_identifiers + [
    '^com\.apple\.Terminal$',
    '^co\.zeit\.hyperterm$',
    '^co\.zeit\.hyper$',
  ]

  vi_bundle_identifiers = [
    '^org\.vim\.', # prefix
  ]

  virtual_machine_bundle_identifiers = [
    '^com\.vmware\.fusion$',
    '^com\.vmware\.horizon$',
    '^com\.vmware\.view$',
    '^com\.parallels\.desktop$',
    '^com\.parallels\.vm$',
    '^com\.parallels\.desktop\.console$',
    '^org\.virtualbox\.app\.VirtualBoxVM$',
    '^com\.vmware\.proxyApp\.', # prefix
    '^com\.parallels\.winapp\.', # prefix
  ]

  x11_bundle_identifiers = [
    '^org\.x\.X11$',
    '^com\.apple\.x11$',
    '^org\.macosforge\.xquartz\.X11$',
    '^org\.macports\.X11$',
  ]

  word_bundle_identifiers = [
    '^com\.microsoft\.Word$'
  ]
  powerpoint_bundle_identifers = [
    '^com\.microsoft\.Powerpoint$'
  ]
  excel_bundle_identifers = [
    '^com\.microsoft\.Excel$'
  ]

  # ----------------------------------------

  bundle_identifiers = []

  to_array(app_aliases).each do |app_alias|
    case app_alias
    when 'finder'
      bundle_identifiers.concat(finder_bundle_identifiers)

    when 'preview'
      bundle_identifiers.concat(preview_bundle_identifiers)

    when 'mac_tab'
      bundle_identifiers.concat(finder_bundle_identifiers)
      bundle_identifiers.concat(preview_bundle_identifiers)
      bundle_identifiers.concat(safari_bundle_identifiers)

    when 'iterm2'
      bundle_identifiers.concat(iterm2_bundle_identifiers)

    when 'terminal'
      bundle_identifiers.concat(terminal_bundle_identifiers)

    when 'emacs'
      bundle_identifiers.concat(emacs_bundle_identifiers)

    when 'emacs_key_bindings_exception'
      bundle_identifiers.concat(emacs_bundle_identifiers)
      bundle_identifiers.concat(remote_desktop_bundle_identifiers)
      bundle_identifiers.concat(terminal_bundle_identifiers)
      bundle_identifiers.concat(vi_bundle_identifiers)
      bundle_identifiers.concat(virtual_machine_bundle_identifiers)
      bundle_identifiers.concat(x11_bundle_identifiers)

    when 'remote_desktop'
      bundle_identifiers.concat(remote_desktop_bundle_identifiers)

    when 'vi'
      bundle_identifiers.concat(vi_bundle_identifiers)

    when 'virtual_machine'
      bundle_identifiers.concat(virtual_machine_bundle_identifiers)

    when 'browser'
      bundle_identifiers.concat(browser_bundle_identifiers)

    when 'word'
      bundle_identifiers.concat(word_bundle_identifiers)

    when 'powerpoint'
      bundle_identifiers.concat(powerpoint_bundle_identifers)

    when 'excel'
      bundle_identifiers.concat(excel_bundle_identifers)

    when 'office'
      bundle_identifiers.concat(word_bundle_identifiers)
      bundle_identifiers.concat(powerpoint_bundle_identifers)
      bundle_identifiers.concat(excel_bundle_identifers)

    when 'vim_emu_exception'
      bundle_identifiers.concat(emacs_bundle_identifiers)
      bundle_identifiers.concat(remote_desktop_bundle_identifiers)
      bundle_identifiers.concat(terminal_bundle_identifiers)
      bundle_identifiers.concat(vi_bundle_identifiers)
      bundle_identifiers.concat(virtual_machine_bundle_identifiers)
      bundle_identifiers.concat(x11_bundle_identifiers)
      bundle_identifiers.concat(browser_bundle_identifiers)

    else
      $stderr << "unknown app_alias: #{app_alias}\n"
    end
  end

  unless bundle_identifiers.empty?
    data = {
      "type" => type,
      "bundle_identifiers" => bundle_identifiers
    }
    make_data(data, as_json)
  end
end

def frontmost_application_if(app_aliases, as_json=true)
  frontmost_application('frontmost_application_if', app_aliases, as_json)
end

def frontmost_application_unless(app_aliases, as_json=true)
  frontmost_application('frontmost_application_unless', app_aliases, as_json)
end

def device(type, device_aliases, as_json=true)
  hhkb_id = {"vendor_id": 2131}

  # ----------------------------------------

  ids = []

  to_array(device_aliases).each do |device_alias|
    case device_alias
    when 'hhkb'
      ids << hhkb_id

    else
      $stderr << "unknown hhkb_alias: #{device_aliases}\n"
    end
  end

  unless ids.empty?
    data = {
      "type" => type,
      "identifiers" => ids
    }
    make_data(data, as_json)
  end
end

def device_if(device_aliases, as_json=true)
  device('device_if', device_aliases, as_json)
end

def device_unless(device_alias, as_json=true)
  device('device_unless', device_aliases, as_json)
end

def input_source(type, input_source_aliases, as_json=true)
  input_sources = []
  to_array(input_source_aliases).each do |input_source_alias|
    if input_source_alias.is_a? Hash
      input_sources << input_source_alias
    end
    if input_source_alias.include?("keylayout")
      input_sources << { "input_source_id": input_source_alias}
    elsif input_source_alias.include?("inputmethod")
      input_sources << { "input_mode_id": input_source_alias}
    else
      input_sources << { "language": input_source_alias}
    end
  end

  unless input_sources.empty?
    data = {
      "type" => type,
      "input_sources" => input_sources
    }
    make_data(data, as_json)
  end
end

def input_source_if(input_source_aliases, as_json=true)
  input_source('input_source_if', input_source_aliases, as_json)
end

def input_source_unless(input_source_aliases, as_json=true)
  input_source('input_source_unless', input_source_aliases, as_json)
end

def vim_emu(source_keys_list: :source_keys_list, dest_keys_list: :dest_keys_list, from_mandatory_modifiers: [], from_optional_modifiers: [], to_pre_events: [], to_modifiers: [], to_post_events: [], to_if_alone: [], to_after_key_up: [], conditions: "", as_json: false, mode: "", move: 0)
  unless source_keys_list.is_a? Array
    source_keys_list = [source_keys_list]
    dest_keys_list = [dest_keys_list]
    to_if_alone = [to_array(to_if_alone)]
  end
  conditions_vim_emu_common = [frontmost_application_unless("vim_emu_exception", false)]
  conditions_vim_emu_common += to_array(conditions) unless conditions == ""
  line = 0
  if move >= 10 and mode == ""
    mode = ["normal", "visual", "y", "d", "c"]
    if move >= 20
      mode.push("visual_line")
      line = 1
    end
  end
  mode = to_array(mode)

  data = []
  mode.each do |m|
    conditions_vim_emu = deepcopy(conditions_vim_emu_common)
    if m != "" and m != "insert"
      conditions_vim_emu += [{"type": "variable_if", "name": "vim_emu_#{m}", "value": 1}]
    end

    dest_keys_list_vim_emu = []
    if move >= 10 and ["visual", "visual_line", "y", "d", "c"].include? m
      dest_keys_list.each do |to_key|
        events = []
        if to_key.is_a? String
          events << [to_key, to_modifiers]
        elsif to_key.is_a? Array
          to_key.each do |e|
            events << e
          end
        else
          events << to_key
        end
        events = hash_to(deepcopy(events))
        events.each do |e|
          if e.key? "key_code"
            e["modifiers"] = [] unless e.key? "modifiers"
            e["modifiers"] << "shift"
          end
        end
        dest_keys_list_vim_emu << events
      end
    else
      dest_keys_list_vim_emu = deepcopy(dest_keys_list)
    end

    repeat = move % 10 == 0 ? [1] : (1..9).to_a.reverse
    repeat.each do |r|
      dest_keys_list_repeat = []
      dest_keys_list_vim_emu.each do |k|
        keys_list = []
        r.times do |i|
          keys_list += to_array(k)
        end
        if move  >= 10
          if m == "y"
            keys_list += [["c", ["command"]], ["left_arrow"]] + vim_emu_mode(normal: 1, line: line)
          elsif m == "d"
            keys_list += [["x", ["command"]]] + vim_emu_mode(normal: 1, line: line)
          elsif m == "c"
            keys_list += [["x", ["command"]]] + vim_emu_mode(line: line)
          end
        end
        dest_keys_list_repeat.push(keys_list)
      end
      conditions_repeat = deepcopy(conditions_vim_emu)
      conditions_repeat += [{"type": "variable_if", "name": "vim_emu_n", "value": r}] if r > 1

      data += each_key(
        source_keys_list: source_keys_list,
        dest_keys_list: dest_keys_list_repeat,
        from_mandatory_modifiers: from_mandatory_modifiers,
        from_optional_modifiers: from_optional_modifiers,
        to_pre_events: to_pre_events,
        to_modifiers: to_modifiers,
        to_post_events: to_post_events,
        to_if_alone: to_if_alone,
        to_after_key_up: to_after_key_up,
        conditions: conditions_repeat,
        as_json: false
      )
    end
  end
  make_data(data, as_json)
end

def vim_emu_modes(list="change")
  normal_modes = ["normal"]
  visual_modes = ["visual", "visual_line"]
  command_modes = ["command", "command_w"]
  ydc_modes = ["y", "d", "c"]
  replace_modes = ["r", "r_cont"]
  search_modes = ["search", "search_input"]
  insert_modes = ["insert"]
  other_modes = ["g", "z"]
  values = ["line", "n"]

  main_modes = normal_modes + visual_modes + command_modes
  sub_modes = ydc_modes + other_modes
  all_modes = main_modes + replace_modes + sub_modes + insert_modes

  if list == "change"
    all_modes + ["n"]
  elsif list == "disable"
    main_modes + sub_modes
  elsif list == "select"
    visual_modes + ydc_modes
  else
    all_modes + values
  end
end

def vim_emu_mode(normal: 0, visual: 0, visual_line: 0, command: 0, command_w: 0, y:0, d: 0, c: 0, g: 0, r:0, r_cont: 0, search_input: 0, search: 0, z: 0, insert: 0, line: -1, as_json: false)
  # vim_emu_mode() -> insert mode
  any = 0
  modes = vim_emu_modes("change")
  modes.each do |m|
    if eval(m) == 1
      any = 1
      break
    end
  end
  insert = 1 if any == 0

  # Always reset n at mode change
  n = 0
  modes = modes + ["n"]

  # Change line mode only if it is given
  modes += ["line"] if line != -1

  data = []
  (modes + ["n"]).each do |m|
    data.push({"set_variable": {"name": "vim_emu_#{m}", "value": eval(m)}})
  end
  make_data(data, as_json)
end

def vim_emu_esc(source_keys_list, as_json=false)
  unless source_keys_list.is_a? Array
    source_keys_list = [source_keys_list]
  end
  dest_keys_list = Array.new(source_keys_list.size, [])
  data = []
  data += vim_emu(
    source_keys_list: source_keys_list,
    dest_keys_list: dest_keys_list,
    to_post_events: [["left_arrow"]] + vim_emu_mode(normal: 1),
    mode: ["visual", "visual_line"],
  )
  data += vim_emu(
    source_keys_list: source_keys_list,
    dest_keys_list: dest_keys_list,
    to_post_events: hash_to([["tab"], ["tab"], ["spacebar"]]) + vim_emu_mode(normal: 1),
    mode: ["search", "search_input"]
  )
  data += vim_emu(
    source_keys_list: source_keys_list,
    dest_keys_list: dest_keys_list,
    to_post_events: vim_emu_mode(normal: 1),
  )
  make_data(data, as_json)
end

def vim_emu_simul(key1, key2, key1_normal, key1_visual, as_json=false)
  dest_keys_list = [{"set_variable": {"name": "vim_emu_simul", "value": 1}}]
  to_after_key_up = [{"set_variable": {"name": "vim_emu_simul", "value": 0}}]
  data = []
  data += vim_emu(
    source_keys_list: key1,
    dest_keys_list: dest_keys_list,
    to_if_alone: key1_normal,
    to_after_key_up: to_after_key_up,
    mode: ["normal"],
  )
  data += vim_emu(
    source_keys_list: key1,
    dest_keys_list: dest_keys_list,
    to_if_alone: key1_visual,
    to_after_key_up: to_after_key_up,
    mode: ["visual", "visual_line"],
  )
  data += vim_emu(
    source_keys_list: key1,
    dest_keys_list: dest_keys_list,
    to_if_alone: hash_to([[key1]]),
    to_after_key_up: to_after_key_up,
    conditions: [{"type": "variable_unless", "name": "vim_emu_insert", "value": 0}],
    mode: "",
  )

  data += vim_emu(
    source_keys_list: key2,
    dest_keys_list: vim_emu_mode(),
    conditions: [{"type": "variable_if", "name": "vim_emu_simul", "value": 1}],
    mode: ["normal"],
  )
  data += vim_emu(
    source_keys_list: key2,
    dest_keys_list: [["left_arrow"]] + vim_emu_mode(normal: 1),
    conditions: [{"type": "variable_if", "name": "vim_emu_simul", "value": 1}],
    mode: ["visual", "visual_line"],
  )
  data += vim_emu(
    source_keys_list: key2,
    dest_keys_list: vim_emu_mode(normal: 1),
    conditions: [
      {"type": "variable_if", "name": "vim_emu_simul", "value": 1},
      {"type": "variable_unless", "name": "vim_emu_insert", "value": 0},
    ],
    mode: "",
  )

  make_data(data, as_json)
end

number_letters = ("1".."9").to_a
alphabet_letters = ("a".."z").to_a
other_letters = ["spacebar", "hyphen", "equal_sign", "open_bracket", "close_bracket", "backslash", "non_us_pound", "semicolon", "quote", "grave_accent_and_tilde", "comma", "period", "slash"]
all_letters = number_letters + alphabet_letters + other_letters
all_letters_array = []
all_letters.each do |l|
  all_letters_array.push([l])
end

template = ERB.new $stdin.read
puts JSON.pretty_generate(JSON.parse(template.result))
