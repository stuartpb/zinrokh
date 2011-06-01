--Libraries------------------------------------------------------------------

--Interface
local iup = require "iuplua"
--Loading the icon
local im = require "imlua"
require "iupluaim"
--Enumerating the available sets
local lfs = require "lfs"

--Settings-------------------------------------------------------------------
--The directory to look for runsets in.
local runsets_dir = "runsets"
--The runset to load at startup.
local default_runset = "sample"

--Constants------------------------------------------------------------------
local icon_filename = "trade_archaeology_zinrokh-sword.jpg"

--Helper functions-----------------------------------------------------------

--replaces the elements in the given IUP parent
--with the ones in the given table.
local function populate(parent,newkids)
  --destroy any current deploy buttons
  local oldkid = iup.GetNextChild(parent, nil)
  while oldkid do
    iup.Destroy(oldkid)
    oldkid = iup.GetNextChild(parent, nil)
  end
  for i=1, #newkids do
    local newkid = newkids[i]
    iup.Append(parent,newkid)
    iup.Map(newkid)
  end
end

--Returns the reverse of the IUP boolean
local function yninverse(yn)
  yn = tostring(yn) and string.upper(yn)
  if yn == "YES" then return "NO"
  elseif yn == "NO" then return "YES" end
end

--Pseudo-globals-------------------------------------------------------------

--The name of the active runset.
local runset
--The contents of the active runset.
local runs
--The container for functions
local report

--IUP objects------------------------------------------------------
--The application window.
local dlg
--The label at the bottom of the dialog.
local statuslabel
--The container for the status label and the "More..." button.
local statusbar
--The text field for the log of details.
local statuslog
--The dialog containing the status log.
local logdialog
--The container for the buttons of the actions.
local buttonbox
--The menu listing runsets.
local runset_menu
--The menu item for toggling topmost status.
local topmost_mitem

--Function definitions-------------------------------------------------------

report = {}

function report.summary(s)
  statuslabel.title = s
end
report.error = report.summary
function report.details(s)
  statuslog.value = statuslog.value..s..'\n'
end

--Interface functions----------------------------------------------
local function toggle_topmost()
  local newstate = yninverse(dlg.topmost or "NO")
  dlg.topmost = newstate
  topmost_mitem.value = newstate
end

--Action loading---------------------------------------------------
local function load_runs()
  success, value = pcall(dofile,
    runsets_dir..'/'..runset..'.lua')

  if success then
    runs = value
    return true
  else
    return success, value
  end
end

local function make_buttons()
  local newbuttons={}

  for i=1, #runs do
    local run = runs[i]
    newbuttons[i] =
      iup.button{
        title = run.name,
        action = function(self)
          run:run(report)
        end,
        expand = "YES"}
  end

  populate(buttonbox,newbuttons)
  iup.Refresh(buttonbox)
  iup.Refresh(dlg)
end

local function load_buttons()
  local success, message = load_runs()
  if success then
    report.summary(string.format(
      'Runset "%s" loaded successfully',
      runset))
    make_buttons()
  else report.error(message)
  end
end

local function load_runset_menu()
  local rset_items={}
  for rset in lfs.dir(runsets_dir) do
    rset = string.match(rset,"^(.-)%.lua")
    if rset then
      rset_items[#rset_items+1]=iup.item{
        title = rset,
        value = rset==runset and "YES",
        action=function(self)
          self.value="YES"
          runset=rset
          load_buttons()
        end
      }
    end
  end
  populate(runset_menu, rset_items)
end

local function refresh()
  load_buttons()
  load_runset_menu()
end

--Object construction--------------------------------------------------------

statuslabel = iup.label{
  expand="horizontal",
  title="Ready."
}

statusbar = iup.hbox{
  margin="3x3",
  alignment="ACENTER";
  statuslabel, iup.fill{},
  iup.button{
    title = "More",
    action = function() logdialog:popup() end
  }
}

statuslog = iup.text{
  multiline="yes", expand="yes", value="",
  rastersize="400x300", readonly="yes"
}

logdialog = iup.dialog{
  title="More..."; statuslog
}

buttonbox = iup.vbox{
  nmargin="3x3", ngap="3x3"}

runset_menu = iup.menu{radio="YES"}

topmost_mitem = iup.item{
  title="Always On Top\tCtrl+T"; value="NO"}

dlg = iup.dialog{
  title="Zin'rokh, Deployer of Worlds",
  icon=iup.LoadImage(icon_filename),
  shrink="YES",
  size="THIRDxHALF",
  menu=iup.menu{
    {"File",iup.menu{
      iup.item{title = "Refresh\tF5, Ctrl+R";
        action = refresh},
      {},
      iup.item{title="Quit";
        action = iup.ExitLoop}
    }},
    {"Runsets",runset_menu},
    {"Options",iup.menu{
      topmost_mitem
    }},
  };
  iup.vbox{
    buttonbox,
    iup.label{separator="horizontal"},
    statusbar
  }
}

--Object callbacks-----------------------------------------------------------

topmost_mitem.action = toggle_topmost

function dlg:k_any(c)
  if c==iup.K_F5 or c==iup.K_cR then
    refresh()
  elseif c==iup.K_cT then
    toggle_topmost()
  end
end

--Execution------------------------------------------------------------------

--Initialize the selected runset
runset = default_runset

refresh()

dlg:show()

iup.MainLoop()

