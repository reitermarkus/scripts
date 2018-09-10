require 'open3'

# Example usage:
#
#   tv = FireTV.new('fire-tv-stick-wohnzimmer.local')
#
#   tv.search
#   sleep(2)
#   tv.type('This is just a demo.')

class AndroidDebugBridge
  class ConnectionError < RuntimeError; end

  EXECUTABLE = 'adb'.freeze
  DEFAULT_PORT = 5555

  def initialize(host, port = DEFAULT_PORT)
    @host = "#{host}:#{port}"
    @connected = false

    self
  end

  def connect
    stdin, stdout, stderr, wait_thr = command('connect', @host)
    stdin.close

    raise ConnectionError, stdout if stdout =~ /unable to connect/

    @connected = true
    self
  end

  def disconnect
    stdin, stdout, stderr, wait_thr = command('disconnect', @host)
    stdin.close

    raise ConnectionError, stdout if stdout =~ /No such device/

    @connected = false
    self
  end

  def connected?
    @connected
  end

  def shell_command(*args)
    connect unless connected?
    command('shell', *args)
  end

  def command(*args)
    Open3.popen3(EXECUTABLE, '-s', @host, *args)
  end
end

class FireTV
  KEYEVENT_ALIASES = {
    up:              :dpad_up,
    down:            :dpad_down,
    left:            :dpad_left,
    right:           :dpad_right,
    play_pause:      :media_play_pause,
    play:            :media_play_pause,
    pause:           :media_play_pause,
    prev:            :media_rewind,
    next:            :media_fast_forward,
    delete:          :del,
    keyboard_layout: :sym,
    :','  =>         :comma,
    :'.'  =>         :period,
    :"\t" =>         :tab,
    :"\ " =>         :space,
    :'/'  =>         :slash,
    :"\\" =>         :backslash,
    :';'  =>         :semicolon,
    :"'"  =>         :apostrophe,
    :'+'  =>         :plus,
    :'-'  =>         :minus,
    :'='  =>         :equals,
    :'`'  =>         :grave,
    :'@'  =>         :at,
    :'['  =>         :left_bracket,
    :']'  =>         :right_bracket,
    :'*'  =>         :star,
    :'#'  =>         :pound,
  }.freeze

  KEYEVENTS = [
    :dpad_up,
    :dpad_down,
    :dpad_left,
    :dpad_right,
    :dpad_center,
    :enter,
    :back,
    :menu,
    :home,
    :media_play_pause,
    :media_rewind,
    :media_fast_forward,
    :search,
    :power,

    # Keyboard
    :sym,
    :del,

    # Characters
    :'0',
    :'1',
    :'2',
    :'3',
    :'4',
    :'5',
    :'6',
    :'7',
    :'8',
    :'9',
    :a,
    :b,
    :c,
    :d,
    :e,
    :f,
    :g,
    :h,
    :i,
    :j,
    :k,
    :l,
    :m,
    :n,
    :o,
    :p,
    :q,
    :r,
    :s,
    :t,
    :u,
    :v,
    :w,
    :x,
    :y,
    :z,
    :star,
    :pound,
    :comma,
    :semicolon,
    :period,
    :tab,
    :space,
    :grave,
    :minus,
    :equals,
    :left_bracket,
    :right_bracket,
    :backslash,
    :apostrophe,
    :slash,
    :at,
    :plus,

    # Game Controller
    :button_a,
    :button_b,
    :button_x,
    :button_y,
    :button_l1,
    :button_r1,
  ].each_with_object({}) { |e, h| h[e] = e }
   .merge(KEYEVENT_ALIASES)
   .freeze

  def initialize(host, port = nil)
    @adb = AndroidDebugBridge.new(host, *port).connect
  end

  KEYEVENTS.keys.each do |key|
    define_method(key) do
      keyevent(key)
    end
  end

  def type(text)
    text.downcase
        .gsub(%r{[^A-Za-z0-9\,\.\t\ \/\\\;\'\+\-\=\`\@\[\]\*\#]}, ' ')
        .each_char do |c|
          send(c)
          sleep(0.5)
        end
  end

  private

  def get_keycode(name)
    keyevent = KEYEVENTS.fetch(name.to_sym, :undefined)
    "KEYCODE_#{keyevent.to_s.upcase}"
  end

  def keyevent(name)
    keyevent = get_keycode(name)
    @adb.shell_command('input', 'keyevent', keyevent.to_s)
  end
end
