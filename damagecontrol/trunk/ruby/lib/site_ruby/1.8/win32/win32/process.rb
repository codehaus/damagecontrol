require "win32ole"
require "socket"
require "parsedate"
require "strongtyping"
include StrongTyping

class WinProcessError < RuntimeError; end
class WinProcess

   # create_flags constants
   DEBUG_PROCESS              = 1
   DEBUG_ONLY_THIS_PROCESS    = 2
   CREATE_SUSPENDED           = 4
   DETACHED_PROCESS           = 8
   CREATE_NEW_CONSOLE         = 16
   CREATE_NEW_PROCESS_GROUP   = 512
   CREATE_UNICODE_ENVIRONMENT = 1024
   CREATE_DEFAULT_ERROR_MODE  = 67108864
   
   # error_mode constants
   FAIL_CRITICAL_ERRORS      = 1
   NO_ALIGNMENT_FAULT_EXCEPT = 2
   NO_GP_FAULT_ERROR_BOX     = 4
   NO_OPEN_FILE_ERROR_BOX    = 8
   
   # fill_attribute constants
   FG_BLUE      = 1
   FG_GREEN     = 2
   FG_RED       = 4
   FG_INTENSITY = 8
   BG_BLUE      = 16
   BG_GREEN     = 32
   BG_RED       = 64
   BG_INTENSITY = 128
   
   # priority_class constants
   NORMAL       = 32
   IDLE         = 64
   HIGH         = 128
   REALTIME     = 256
   ABOVE_NORMAL = 16384 # Win2k or later
   BELOW_NORMAL = 32768 # Win2k or later
   
   # show_window constants
   SW_HIDE            = 0
   SW_NORMAL          = 1
   SW_SHOWMINIMIZED   = 2
   SW_SHOWMAXIMIZED   = 3
   SW_SHOWNOACTIVATE  = 4
   SW_SHOW            = 5
   SW_MINIMIZE        = 6
   SW_SHOWMINNOACTIVE = 7
   SW_SHOWNA          = 8
   SW_RESTORE         = 9
   SW_SHOWDEFAULT     = 10
   SW_FORCEMINIMIZE   = 11
   
   attr_reader :cmdline, :current_dir
   attr_reader :create_flags, :env_variables, :error_mode, :fill_attribute
   attr_reader :priority_class, :show_window, :title, :winstation_desktop
   attr_reader :x_coord, :x_count_chars, :x_size
   attr_reader :y_coord, :y_count_chars, :y_size
   
   def initialize(host=Socket.gethostname)
      str       = "winmgmts://#{host}/root/cimv2:"
      proc_str  = str + "Win32_Process"
      start_str = str + "Win32_ProcessStartup"
      
      @host = host
      @process = WIN32OLE.connect(proc_str)
      @startup = WIN32OLE.connect(start_str)
      yield self if block_given?
   end
   
   def create
      rv = @process.Create(
         @cmdline,
         @current_dir,
         @startup,
         nil
      )
      if 0 != rv
         raise WinProcessError, rv
      end
      @process.ProcessId
   end
   
   def cmdline=(cmd)
      expect(cmd,String)
      @cmdline = cmd
   end
   
   def current_dir=(dir)
      expect(dir,String)
      @current_dir = dir
   end

   def create_flags=(flags)
      expect(flags,Integer)
      @startup.CreateFlags = flags
      @flags = flags
   end
   
   def env_variables=(vars)
      expect(vars,Array)
      @startup.EnvironmentVariables = vars
      @env_variables = vars
   end
   
   def error_mode=(mode)
      expect(mode,Integer)
      @startup.ErrorMode = mode
      @error_mode = mode
   end
   
   def fill_attribute(num)
      expect(num,Integer)
      @startup.FillAttribute = num
      @fill_attribute = num
   end
   
   def priority_class=(num)
      expect(num,Integer)
      @startup.PriorityClass = num
      @priority_class = num
   end
   
   def show_window=(num)
      expect(num,Integer)
      @startup.ShowWindow = num
      @show_window = num
   end
   
   def title=(str)
      expect(str,String)
      @startup.Title = str
      @title = str
   end
   
   def winstation_desktop=(desktop)
      expect(desktop,String)
      @startup.WinstationDesktop = desktop
      @winstation_desktop = desktop
   end
   
   def x_coord=(x)
      expect(x,Integer)
      @startup.X = x
      @x_coord = x
   end
   
   def x_count_chars=(num)
      expect(num,Integer)
      @startup.XCountChars = num
      @x_count_chars = num
   end
   
   def x_size(num)
      expect(num,Integer)
      @startup.XSize = num
      @x_size = num
   end
   
   def y_coord=(y)
      expect(y,Integer)
      @startup.Y = y
      @y_coord = y
   end
   
   def y_count_chars=(num)
      expect(num,Integer)
      @startup.YCountChars = num
      @y_count_chars = num
   end
   
   def y_size(num)
      expect(num,Integer)
      @startup.YSize = num
      @y_size = num
   end
  
end

if $0 == __FILE__
   w = WinProcess.new{ |wp|
      wp.cmdline = "notepad.exe"
      wp
   }
   pid = w.create
   p pid
end