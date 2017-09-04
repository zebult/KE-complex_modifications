#!/usr/bin/env ruby

require 'erb'
require 'json'

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
  elsif key.start_with?("button")
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

def each_key(source_keys_list: :source_keys_list, dest_keys_list: :dest_keys_list, from_mandatory_modifiers: [], from_optional_modifiers: [], to_pre_events: [], to_modifiers: [], to_post_events: [], conditions: [], as_json: false)
  unless source_keys_list.is_a? Array
    source_keys_list = [source_keys_list]
    dest_keys_list = [dest_keys_list]
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
  browser_bundle_identifiers = [
    '^org\.mozilla\.firefox$',
    '^com\.google\.Chrome$',
    '^com\.apple\.Safari$',
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

    when 'vim_emu'
      bundle_identifiers.concat(emacs_bundle_identifiers)
      bundle_identifiers.concat(remote_desktop_bundle_identifiers)
      bundle_identifiers.concat(terminal_bundle_identifiers)
      bundle_identifiers.concat(vi_bundle_identifiers)
      bundle_identifiers.concat(virtual_machine_bundle_identifiers)
      bundle_identifiers.concat(x11_bundle_identifiers)
      bundle_identifiers.concat(remote_desktop_bundle_identifiers)
      bundle_identifiers.concat(virtual_machine_bundle_identifiers)
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

def device_unless(app_aliases, as_json=true)
  device('device_unless', device_aliases, as_json)
end

def vim_emu(source_keys_list: :source_keys_list, dest_keys_list: :dest_keys_list, from_mandatory_modifiers: [], from_optional_modifiers: [], to_pre_events: [], to_modifiers: [], to_post_events: [], conditions: "", as_json: false, mode: "", move: 0)
  unless source_keys_list.is_a? Array
    source_keys_list = [source_keys_list]
    dest_keys_list = [dest_keys_list]
  end
  conditions_vim_emu_common = [frontmost_application_unless("vim_emu", false)]
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
    if move >= 10 and ["visual", "visual_line", "y", "d", "c"].include?(m)
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
          if e.key?("key_code")
            e["modifiers"] = [] unless e.key?("modifiers")
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
        conditions: conditions_repeat,
        as_json: false
      )
    end
  end
  make_data(data, as_json)
end

def vim_emu_mode(normal: 0, visual: 0, visual_line: 0, command: 0, command_w: 0, y:0, d: 0, c: 0, g: 0, r:0, r_cont: 0, search_input: 0, search: 0, z: 0, line: -1, as_json: false)
  data = [
    {"set_variable": {"name": "vim_emu_normal", "value": normal}},
    {"set_variable": {"name": "vim_emu_visual", "value": visual}},
    {"set_variable": {"name": "vim_emu_visual_line", "value": visual_line}},
    {"set_variable": {"name": "vim_emu_command", "value": command}},
    {"set_variable": {"name": "vim_emu_command_w", "value": command_w}},
    {"set_variable": {"name": "vim_emu_y", "value": y}},
    {"set_variable": {"name": "vim_emu_d", "value": d}},
    {"set_variable": {"name": "vim_emu_c", "value": c}},
    {"set_variable": {"name": "vim_emu_g", "value": g}},
    {"set_variable": {"name": "vim_emu_r", "value": r}},
    {"set_variable": {"name": "vim_emu_r_cont", "value": r_cont}},
    {"set_variable": {"name": "vim_emu_search_input", "value": search_input}},
    {"set_variable": {"name": "vim_emu_search", "value": search}},
    {"set_variable": {"name": "vim_emu_z", "value": z}},
    {"set_variable": {"name": "vim_emu_n", "value": 0}},
  ]
  data += [{"set_variable": {"name": "vim_emu_line", "value": line}}] if line != -1
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
