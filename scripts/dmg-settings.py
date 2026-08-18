import os

application = defines["app"]  # noqa: F821
background = defines["background"]  # noqa: F821
volume_icon = defines.get("volume_icon")  # noqa: F821
app_name = os.path.basename(application)

format = "UDZO"
filesystem = "HFS+"

files = [application]
symlinks = {"Applications": "/Applications"}
hide_extensions = [app_name]

if volume_icon and os.path.isfile(volume_icon):
    icon = volume_icon

icon_locations = {
    app_name: (378, 164),
    "Applications": (530, 216),
}

window_rect = ((200, 120), (600, 400))
default_view = "icon-view"
show_status_bar = False
show_tab_view = False
show_toolbar = False
show_pathbar = False
show_sidebar = False
show_icon_preview = True
include_icon_view_settings = True

arrange_by = None
grid_spacing = 90
scroll_position = (0, 0)
label_pos = "bottom"
text_size = 12
icon_size = 96
