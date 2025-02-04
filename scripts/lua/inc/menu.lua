--
-- (C) 2013-15 - ntop.org
--

dirs = ntop.getDirs()
package.path = dirs.installdir .. "/scripts/lua/modules/?.lua;" .. package.path
if ( (dirs.scriptdir ~= nil) and (dirs.scriptdir ~= "")) then package.path = dirs.scriptdir .. "/lua/modules/?.lua;" .. package.path end
require "lua_utils"

prefs = ntop.getPrefs()
names = interface.getIfNames()
num_ifaces = 0
for k,v in pairs(names) do num_ifaces = num_ifaces+1 end

print [[
      <div class="masthead">
        <ul class="nav nav-pills pull-right">
   ]]


interface.select(ifname)
ifId = interface.getStats().id

if active_page == "home" or active_page == "about" then
  print [[ <li class="dropdown active"> ]]
else
  print [[ <li class="dropdown"> ]]
end

print [[
      <a class="dropdown-toggle" data-toggle="dropdown" href="#">
        <i class="fa fa-home fa-lg"></i> <b class="caret"></b>
      </a>
    <ul class="dropdown-menu">
      <li><a href="]]
print(ntop.getHttpPrefix())
print [[/lua/about.lua"><i class="fa fa-question-circle"></i> About ntopng</a></li>
      <li><a href="http://blog.ntop.org/" target="_blank"><i class="fa fa-rss"></i> ntop Blog <i class="fa fa-external-link"></i></a></li>
      <li><a href="https://github.com/ntop/ntopng/issues" target="_blank"><i class="fa fa-bug"></i> Report an Issue <i class="fa fa-external-link"></i></a></li>
      <li class="divider"></li>
      <li><a href="]]

print(ntop.getHttpPrefix())
if(ntop.isPro()) then
   print("/lua/pro/dashboard.lua")
else
   print("/lua/index.lua")
end

print [["><i class="fa fa-dashboard"></i> Dashboard</a></li>
      ]]
if ntop.isPro() and prefs.is_dump_flows_to_mysql_enabled then
  print('<li><a href="'..ntop.getHttpPrefix()..'/lua/pro/db_explorer.lua?ifId='..ifId..'"><i class="fa fa-history"></i> Historical data explorer</a></li>')
end

print [[
  </li>

   ]]
if(ntop.isPro()) then
	print('<li><a href="'..ntop.getHttpPrefix()..'/lua/pro/report.lua"><i class="fa fa-area-chart"></i> Report</a></li>')
end

print [[    </ul>
  </li>

   ]]

_ifstats = aggregateInterfaceStats(interface.getStats())

if(_ifstats.iface_sprobe) then
   url = ntop.getHttpPrefix().."/lua/sflows_stats.lua"
else
   url = ntop.getHttpPrefix().."/lua/flows_stats.lua"
end

if(active_page == "flows") then
   print('<li class="active"><a href="'..url..'">Flows</a></li>')
else
   print('<li><a href="'..url..'">Flows</a></li>')
end

if active_page == "hosts" then
  print [[ <li class="dropdown active"> ]]
else
  print [[ <li class="dropdown"> ]]
end

print [[
      <a class="dropdown-toggle" data-toggle="dropdown" href="#">
        Hosts <b class="caret"></b>
      </a>
    <ul class="dropdown-menu">
      <li><a href="]]
print(ntop.getHttpPrefix())
print [[/lua/hosts_stats.lua">Hosts</a></li>
      ]]

  print('<li><a href="'..ntop.getHttpPrefix()..'/lua/network_stats.lua">Networks</a></li>')

  print('<li><a href="'..ntop.getHttpPrefix()..'/lua/mac_stats.lua">MAC Addresses</a></li>')

  if(ntop.hasGeoIP()) then
     print('<li><a href="'..ntop.getHttpPrefix()..'/lua/as_stats.lua">Autonomous Systems</a></li>')
     print('<li><a href="'..ntop.getHttpPrefix()..'/lua/country_stats.lua">Countries</a></li>')
  end
  print('<li><a href="'..ntop.getHttpPrefix()..'/lua/os_stats.lua">Operating Systems</a></li>')

  if(ntop.hasVLANs()) then
     print('<li><a href="'..ntop.getHttpPrefix()..'/lua/vlan_stats.lua">VLANs</a></li>')
  end

  if(_ifstats.iface_sprobe) then
   print('<li><a href="'..ntop.getHttpPrefix()..'/lua/processes_stats.lua">Processes</a></li>')
end

print('<li><a href="'..ntop.getHttpPrefix()..'/lua/http_servers_stats.lua">HTTP Servers (Local)</a></li>')

print('<li class="divider"></li>')

print('<li><a href="'..ntop.getHttpPrefix()..'/lua/top_hosts.lua"><i class="fa fa-trophy"></i> Top Hosts (Local)</a></li>')

if(_ifstats.iface_sprobe) then
   print('<li><a href="'..ntop.getHttpPrefix()..'/lua/sprobe.lua"><i class="fa fa-flag"></i> System Interactions</a></li>\n')
end


if(not(isLoopback(ifname))) then
   print [[
	    <li><a href="]]
print(ntop.getHttpPrefix())
print [[/lua/hosts_geomap.lua"><i class="fa fa-map-marker"></i> Geo Map</a></li>
	    <li><a href="]]
print(ntop.getHttpPrefix())
print [[/lua/hosts_treemap.lua"><i class="fa fa-sitemap"></i> Tree Map</a></li>
      ]]
end

print [[
      <li><a href="]]
print(ntop.getHttpPrefix())
print [[/lua/hosts_matrix.lua"><i class="fa fa-th-large"></i> Local Flow Matrix</a></li>
   ]]

if(_ifstats["has_mesh_networks_traffic"]) then
   print [[ <li><a href="]] print(ntop.getHttpPrefix()) print [[/lua/mesh_antenna_stats.lua"><i class="fa fa-wifi"></i> Mesh Antenna Stats</a></li> ]]
end

print("</ul> </li>")


-- Interfaces
if(num_ifaces > 0) then
if active_page == "if_stats" then
  print [[ <li class="dropdown active"> ]]
else
  print [[ <li class="dropdown"> ]]
end

print [[
      <a class="dropdown-toggle" data-toggle="dropdown" href="#">Interfaces <b class="caret"></b>
      </a>
      <ul class="dropdown-menu">
]]

views = {}
ifnames = {}

for v,k in pairs(interface.getIfNames()) do
   interface.select(k)
   _ifstats = interface.getStats()
   ifnames[_ifstats.id] = k
   --io.write(ifnames[_ifstats.id].."=".._ifstats.id.."\n")
   if(_ifstats.isView == true) then views[k] = true end
end

for k,v in pairsByKeys(ifnames, asc) do
   print("      <li>")   
   --io.write(k.."="..v.."\n")

   if(v == ifname) then
      print("<a href=\""..ntop.getHttpPrefix().."/lua/if_stats.lua?id="..k.."\">")
   else
      print("<a href=\""..ntop.getHttpPrefix().."/lua/set_active_interface.lua?id="..k.."\">")
   end
   
   if(v == ifname) then print("<i class=\"fa fa-check\"></i> ") end
   if (isPausedInterface(v)) then  print('<i class="fa fa-pause"></i> ') end
   
   print(getHumanReadableInterfaceName(v..""))
   if(views[v] == true) then print(' <i class="fa fa-eye"></i> ') end
   print("</a>")
   print("</li>\n")
end


print [[

      </ul>
    </li>
]]
end



-- Admin
if active_page == "admin" then
  print [[ <li class="dropdown active"> ]]
else
  print [[ <li class="dropdown"> ]]
end

print [[
      <a class="dropdown-toggle" data-toggle="dropdown" href="#">
        <i class="fa fa-cog fa-lg"></i> <b class="caret"></b>
      </a>
    <ul class="dropdown-menu">
      <li><a href="]]

user_group = ntop.getUserGroup()

if(user_group == "administrator") then
  print(ntop.getHttpPrefix())
  print [[/lua/admin/users.lua"><i class="fa fa-user"></i> Manage Users</a></li>
      ]]
else
  print [[#password_dialog"  data-toggle="modal"><i class="fa fa-user"></i> Change Password</a></li>
      ]]
end

if(user_group == "administrator") then
   print("<li><a href=\""..ntop.getHttpPrefix().."/lua/admin/prefs.lua\"><i class=\"fa fa-flask\"></i> Preferences</a></li>\n")

   if (ntop.isPro()) then
      print("<li><a href=\""..ntop.getHttpPrefix().."/lua/pro/admin/edit_profiles.lua\"><i class=\"fa fa-user-md\"></i> Traffic Profiles</a></li>\n")
      if(false) then
	 print("<li><a href=\""..ntop.getHttpPrefix().."/lua/pro/admin/list_reports.lua\"><i class=\"fa fa-archive\"></i> Reports Archive</a></li>\n")
      end
   end
end

print [[
      <li class="divider"></li>
      <li><a href="]]
print(ntop.getHttpPrefix())
print [[/lua/export_data.lua"><i class="fa fa-share"></i> Export Data</a></li>
    </ul>
    </li>
   ]]

if(_COOKIE["user"] ~= nil and _COOKIE["user"] ~= ntop.getNologinUser()) then
print [[
    <li class="dropdown">
      <a class="dropdown-toggle" data-toggle="dropdown" href="#">
	 <i class="fa fa-user fa-lg"></i> <b class="caret"></b>
      </a>
    <ul class="dropdown-menu">
	 <li><a href="]]
print(ntop.getHttpPrefix())
print [[/lua/logout.lua"><i class="fa fa-power-off"></i> Logout ]]    print(_COOKIE["user"]) print [[</a></li>
    </ul>
    </li>
   ]]
end

if(ntop.getNumQueuedAlerts() > 0) then
print [[
<li>
<a  href="]]
print(ntop.getHttpPrefix())
print [[/lua/show_alerts.lua">
<i class="fa fa-warning fa-lg" style="color: #B94A48;"></i>
</a>
</li>
   ]]
end

if(user_group ~= "administrator") then
   dofile(dirs.installdir .. "/scripts/lua/inc/password_dialog.lua")
end
dofile(dirs.installdir .. "/scripts/lua/inc/search_host_box.lua")

function file_exists(name)
   local f=io.open(name,"r")
   if f~=nil then io.close(f) return true else return false end
end

print("</ul>\n<h3 class=\"muted\"><A href=http://www.ntop.org>")

if(false) then
if(file_exists(dirs.installdir .. "/httpdocs/img/custom_logo.jpg")) then
   logo_path = ntop.getHttpPrefix().."/img/custom_logo.jpg"
else
   logo_path = ntop.getHttpPrefix().."/img/logo.png"
end

print("<img src=\""..logo_path.."\">")
end

print [[
<svg width="103px" height="50px" viewBox="0 0 103 50" version="1.1" xmlns="http://www.w3.org/2000/svg">
<path fill="#fbfbfb" d=" M 0.00 0.00 L 103.00 0.00 L 103.00 50.00 L 0.00 50.00 L 0.00 0.00 Z" />
<path fill="#e0dfdf" d=" M 4.85 1.48 C 6.22 1.31 7.60 1.22 8.98 1.21 C 37.00 1.18 65.02 1.25 93.03 1.19 C 95.53 1.45 98.91 1.02 100.31 3.63 C 101.57 5.50 101.41 7.84 101.46 9.98 C 101.41 20.66 101.49 31.34 101.42 42.02 C 101.47 44.44 100.55 47.12 98.30 48.31 C 95.68 49.45 92.76 48.78 90.01 48.81 C 65.02 48.80 40.02 48.83 15.02 48.80 C 11.70 48.82 8.35 49.28 5.04 48.72 L 5.39 47.64 C 8.24 47.83 11.09 48.07 13.95 48.13 C 39.31 48.15 64.66 48.12 90.02 48.15 C 92.91 48.15 95.79 47.82 98.63 47.31 C 98.05 46.60 97.37 45.99 96.61 45.49 L 95.99 45.06 C 96.80 44.80 98.40 44.30 99.21 44.04 L 99.36 44.03 C 99.50 44.03 99.79 44.02 99.93 44.01 C 100.48 31.44 100.36 18.75 100.14 6.16 C 99.85 5.82 99.28 5.16 99.00 4.83 L 98.05 4.18 C 97.44 3.75 96.83 3.33 96.22 2.91 C 95.08 1.78 93.46 1.86 91.98 1.84 C 65.31 2.00 38.64 1.81 11.97 1.92 C 9.59 1.93 7.19 1.95 4.85 1.48 Z" />
<path fill="#fdc28e" d=" M 2.40 4.64 C 3.22 4.02 4.05 3.42 4.88 2.81 C 35.32 2.80 65.78 2.61 96.22 2.91 C 96.83 3.33 97.44 3.75 98.05 4.18 C 97.94 10.99 97.98 17.80 98.03 24.61 C 94.33 24.55 90.63 24.55 86.93 24.61 C 87.03 20.61 85.58 16.14 81.83 14.17 C 79.15 12.57 75.83 13.14 73.29 14.71 C 72.19 14.27 71.09 13.86 69.98 13.48 C 68.39 13.87 67.26 15.25 67.53 16.92 C 67.45 19.53 67.54 22.13 67.52 24.74 C 67.13 24.69 66.35 24.59 65.97 24.55 C 65.86 21.70 65.76 18.50 63.66 16.31 C 60.13 12.15 52.85 12.14 49.37 16.37 C 47.35 18.58 46.81 21.64 46.81 24.53 C 45.41 24.56 44.01 24.59 42.61 24.62 C 42.59 22.97 42.57 21.32 42.60 19.68 C 43.90 19.29 45.26 19.07 46.53 18.57 C 47.29 17.40 47.41 15.65 46.54 14.51 C 45.32 14.03 44.05 13.72 42.73 13.58 C 42.78 10.95 42.74 6.67 38.89 7.30 C 36.49 8.54 37.22 11.38 36.92 13.57 C 34.23 13.50 32.07 16.35 34.12 18.59 C 34.83 18.84 36.25 19.33 36.97 19.58 C 37.12 21.25 37.06 22.92 37.06 24.59 C 35.75 24.59 34.44 24.59 33.14 24.61 C 32.96 21.36 33.89 17.35 31.15 14.90 C 28.35 12.51 24.15 12.89 21.14 14.66 C 19.28 13.73 16.40 12.75 15.43 15.37 C 15.10 18.44 15.36 21.53 15.28 24.61 C 11.08 24.54 6.88 24.58 2.69 24.58 C 2.10 17.97 2.69 11.28 2.40 4.64 Z" />
<path fill="#fde2cb" d=" M 98.05 4.18 L 99.00 4.83 C 99.13 17.89 98.72 31.00 99.36 44.03 L 99.21 44.04 L 97.99 43.66 C 98.18 37.32 98.14 30.96 98.03 24.61 C 97.98 17.80 97.94 10.99 98.05 4.18 Z" />
<path fill="#919191" d=" M 99.00 4.83 C 99.28 5.16 99.85 5.82 100.14 6.16 C 100.36 18.75 100.48 31.44 99.93 44.01 C 99.79 44.02 99.50 44.03 99.36 44.03 C 98.72 31.00 99.13 17.89 99.00 4.83 Z" />
<path fill="#ffffff" d=" M 36.92 13.57 C 37.22 11.38 36.49 8.54 38.89 7.30 C 42.74 6.67 42.78 10.95 42.73 13.58 C 44.05 13.72 45.32 14.03 46.54 14.51 C 47.41 15.65 47.29 17.40 46.53 18.57 C 45.26 19.07 43.90 19.29 42.60 19.68 C 42.57 21.32 42.59 22.97 42.61 24.62 C 42.16 27.60 44.14 33.15 39.86 33.86 C 35.40 33.43 37.57 27.54 37.06 24.59 C 37.06 22.92 37.12 21.25 36.97 19.58 C 36.25 19.33 34.83 18.84 34.12 18.59 C 32.07 16.35 34.23 13.50 36.92 13.57 Z" />
<path fill="#ffffff" d=" M 21.14 14.66 C 24.15 12.89 28.35 12.51 31.15 14.90 C 33.89 17.35 32.96 21.36 33.14 24.61 C 33.05 27.07 33.29 29.54 32.95 31.99 C 32.16 34.62 27.92 34.40 27.34 31.72 C 27.19 29.35 27.31 26.98 27.29 24.61 C 27.51 22.14 27.48 18.11 24.05 18.23 C 20.81 18.41 20.90 22.23 21.02 24.62 C 20.99 27.08 21.12 29.55 20.95 32.01 C 20.07 34.59 15.97 34.42 15.33 31.76 C 15.20 29.38 15.32 26.99 15.28 24.61 C 15.36 21.53 15.10 18.44 15.43 15.37 C 16.40 12.75 19.28 13.73 21.14 14.66 Z" />
<path fill="#ffffff" d=" M 49.37 16.37 C 52.85 12.14 60.13 12.15 63.66 16.31 C 65.76 18.50 65.86 21.70 65.97 24.55 C 66.06 29.16 62.74 33.71 57.98 34.13 C 52.20 35.30 46.89 30.21 46.81 24.53 C 46.81 21.64 47.35 18.58 49.37 16.37 Z" />
<path fill="#ffffff" d=" M 73.29 14.71 C 75.83 13.14 79.15 12.57 81.83 14.17 C 85.58 16.14 87.03 20.61 86.93 24.61 C 86.64 28.43 84.48 32.37 80.78 33.78 C 78.26 34.69 75.60 34.08 73.23 33.05 C 73.25 35.33 73.62 37.68 73.06 39.92 C 72.06 42.49 67.59 41.88 67.55 39.02 C 67.45 34.26 67.54 29.50 67.52 24.74 C 67.54 22.13 67.45 19.53 67.53 16.92 C 67.26 15.25 68.39 13.87 69.98 13.48 C 71.09 13.86 72.19 14.27 73.29 14.71 Z" />
<path fill="#fdc28e" d=" M 21.02 24.62 C 20.90 22.23 20.81 18.41 24.05 18.23 C 27.48 18.11 27.51 22.14 27.29 24.61 C 25.20 24.57 23.11 24.57 21.02 24.62 Z" />
<path fill="#fdc28e" d=" M 52.65 24.61 C 52.24 21.99 53.91 18.42 57.03 18.94 C 59.66 19.25 60.63 22.31 60.35 24.61 C 57.79 24.56 55.22 24.56 52.65 24.61 Z" />
<path fill="#fdc28e" d=" M 72.96 25.45 C 73.30 22.95 73.64 19.11 76.92 18.92 C 80.68 18.62 81.33 23.07 81.11 25.88 L 80.87 25.48 L 80.33 24.57 C 78.09 24.72 75.61 24.01 73.55 25.17 L 72.96 25.45 Z" />
<path fill="#fc8a21" d=" M 2.69 24.58 C 6.88 24.58 11.08 24.54 15.28 24.61 C 15.32 26.99 15.20 29.38 15.33 31.76 C 15.97 34.42 20.07 34.59 20.95 32.01 C 21.12 29.55 20.99 27.08 21.02 24.62 C 23.11 24.57 25.20 24.57 27.29 24.61 C 27.31 26.98 27.19 29.35 27.34 31.72 C 27.92 34.40 32.16 34.62 32.95 31.99 C 33.29 29.54 33.05 27.07 33.14 24.61 C 34.44 24.59 35.75 24.59 37.06 24.59 C 37.57 27.54 35.40 33.43 39.86 33.86 C 44.14 33.15 42.16 27.60 42.61 24.62 C 44.01 24.59 45.41 24.56 46.81 24.53 C 46.89 30.21 52.20 35.30 57.98 34.13 C 62.74 33.71 66.06 29.16 65.97 24.55 C 66.35 24.59 67.13 24.69 67.52 24.74 C 67.54 29.50 67.45 34.26 67.55 39.02 C 67.59 41.88 72.06 42.49 73.06 39.92 C 73.62 37.68 73.25 35.33 73.23 33.05 C 75.60 34.08 78.26 34.69 80.78 33.78 C 84.48 32.37 86.64 28.43 86.93 24.61 C 90.63 24.55 94.33 24.55 98.03 24.61 C 98.14 30.96 98.18 37.32 97.99 43.66 L 99.21 44.04 C 98.40 44.30 96.80 44.80 95.99 45.06 C 65.83 44.97 35.66 44.94 5.50 45.07 L 4.31 45.05 C 3.90 44.64 3.08 43.80 2.67 43.38 C 2.79 37.12 2.76 30.84 2.69 24.58 Z" />
<path fill="#fc8a21" d=" M 52.65 24.61 C 55.22 24.56 57.79 24.56 60.35 24.61 C 60.25 27.09 57.56 29.61 55.11 28.23 C 53.54 27.78 53.08 25.97 52.65 24.61 Z" />
<path fill="#fc8a21" d=" M 73.55 25.17 C 75.61 24.01 78.09 24.72 80.33 24.57 L 80.87 25.48 C 80.22 29.65 73.76 29.42 73.55 25.17 Z" />
<path fill="#fdb26d" d=" M 5.50 45.07 C 35.66 44.94 65.83 44.97 95.99 45.06 L 96.61 45.49 C 94.20 46.38 91.57 45.86 89.06 46.00 C 60.87 45.86 32.65 46.28 4.48 45.79 L 5.50 45.07 Z" />
<path fill="#a2a2a2" d=" M 2.04 44.37 L 4.48 45.79 C 32.65 46.28 60.87 45.86 89.06 46.00 C 91.57 45.86 94.20 46.38 96.61 45.49 C 97.37 45.99 98.05 46.60 98.63 47.31 C 95.79 47.82 92.91 48.15 90.02 48.15 C 64.66 48.12 39.31 48.15 13.95 48.13 C 11.09 48.07 8.24 47.83 5.39 47.64 C 4.55 46.82 2.87 45.19 2.04 44.37 Z" />
</svg>
]]

print("</A></h3>\n</div>\n")

-- select the original interface back to prevent possible issues
interface.select(ifname)

