#define InstallerVersionText SetupSetting("AppVersion")
#define ContextMenuInclude AddBackslash(SourcePath) + "context_menu.generated.iss"

; The context menu layout lives in tools\context_menu.psd1; its code is regenerated on every compile.
#if Exec(GetEnv("SystemRoot") + "\System32\WindowsPowerShell\v1.0\powershell.exe", \
    "-NoProfile -ExecutionPolicy Bypass -File " + AddQuotes(AddBackslash(SourcePath) + "tools\build_menu_iss.ps1") + \
    " -OutputFile " + AddQuotes(ContextMenuInclude), SourcePath, 1, SW_HIDE) != 0
  #error tools\build_menu_iss.ps1 failed to generate context_menu.generated.iss
#endif

[Setup]
AppName=FFActions
AppId=FFActions
AppVersion=1.4.1
DefaultDirName={autopf}\FFActions
DefaultGroupName=FFActions
OutputDir=.
OutputBaseFilename=FFActions_Setup
Compression=lzma
SolidCompression=yes
PrivilegesRequired=admin
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
WizardStyle=modern
DisableProgramGroupPage=yes
AlwaysShowComponentsList=yes
SetupIconFile=tools\icons\ffactions.ico
UninstallDisplayIcon={app}\tools\icons\ffactions.ico
LicenseFile=LICENSE
ShowComponentSizes=no
ExtraDiskSpaceRequired=220000000

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Messages]
english.ComponentsDiscSpaceLabel=Select the modules to install:

[Types]
Name: "complete"; Description: "Complete installation"
Name: "custom"; Description: "Custom installation"; Flags: iscustom

[Components]
Name: "video"; Description: "Video"; Types: complete custom
Name: "video\cut_video"; Description: "Cut video"; Types: complete custom
Name: "video\interpolate"; Description: "Interpolate"; Types: complete custom
Name: "video\remove_audio"; Description: "Remove audio"; Types: complete custom
Name: "video\extract_frames"; Description: "Extract frames"; Types: complete custom
Name: "video\extract_audio"; Description: "Extract audio"; Types: complete custom
Name: "video\create_gif"; Description: "Create GIF"; Types: complete custom
Name: "video\resize_video"; Description: "Resize video"; Types: complete custom
Name: "video\change_speed"; Description: "Change speed"; Types: complete custom
Name: "video\crop_video"; Description: "Crop video"; Types: complete custom
Name: "video\rotate"; Description: "Rotate / flip"; Types: complete custom
Name: "video\compress"; Description: "Compress video"; Types: complete custom
Name: "video\convert"; Description: "Convert"; Types: complete custom
Name: "video\media_info"; Description: "Media info"; Types: complete custom
Name: "audio"; Description: "Audio"; Types: complete custom
Name: "audio\cut_audio"; Description: "Cut audio"; Types: complete custom
Name: "audio\change_speed"; Description: "Change speed"; Types: complete custom
Name: "audio\reverse"; Description: "Reverse audio"; Types: complete custom
Name: "audio\compress"; Description: "Compress audio"; Types: complete custom
Name: "audio\change_pitch"; Description: "Change pitch"; Types: complete custom
Name: "audio\convert"; Description: "Convert"; Types: complete custom
Name: "audio\media_info"; Description: "Media info"; Types: complete custom
Name: "image"; Description: "Image"; Types: complete custom
Name: "image\resize_image"; Description: "Resize image"; Types: complete custom
Name: "image\image_to_pdf"; Description: "Image to PDF"; Types: complete custom
Name: "image\convert"; Description: "Convert"; Types: complete custom
Name: "image\compress"; Description: "Compress"; Types: complete custom
Name: "image\flip"; Description: "Rotate / flip"; Types: complete custom
Name: "image\crop"; Description: "Crop"; Types: complete custom
Name: "image\icon"; Description: "Convert to icon"; Types: complete custom
Name: "image\media_info"; Description: "Media info"; Types: complete custom

[Files]
Source: "actions\cut_video.exe"; DestDir: "{app}\actions"; Flags: ignoreversion; Components: video\cut_video
Source: "actions\interpolate.exe"; DestDir: "{app}\actions"; Flags: ignoreversion; Components: video\interpolate
Source: "actions\convert_to_mp4.exe"; DestDir: "{app}\actions"; Flags: ignoreversion; Components: video\convert
Source: "actions\convert_to_mkv.exe"; DestDir: "{app}\actions"; Flags: ignoreversion; Components: video\convert
Source: "actions\convert_to_avi.exe"; DestDir: "{app}\actions"; Flags: ignoreversion; Components: video\convert
Source: "actions\convert_to_mov.exe"; DestDir: "{app}\actions"; Flags: ignoreversion; Components: video\convert
Source: "actions\convert_to_webm.exe"; DestDir: "{app}\actions"; Flags: ignoreversion; Components: video\convert
Source: "actions\convert_to_m4v.exe"; DestDir: "{app}\actions"; Flags: ignoreversion; Components: video\convert
Source: "actions\remove_audio.exe"; DestDir: "{app}\actions"; Flags: ignoreversion; Components: video\remove_audio
Source: "actions\extract_frames.exe"; DestDir: "{app}\actions"; Flags: ignoreversion; Components: video\extract_frames
Source: "actions\extract_audio_to_mp3.exe"; DestDir: "{app}\actions"; Flags: ignoreversion; Components: video\extract_audio
Source: "actions\extract_audio_to_wav.exe"; DestDir: "{app}\actions"; Flags: ignoreversion; Components: video\extract_audio
Source: "actions\extract_audio_to_flac.exe"; DestDir: "{app}\actions"; Flags: ignoreversion; Components: video\extract_audio
Source: "actions\extract_audio_to_m4a.exe"; DestDir: "{app}\actions"; Flags: ignoreversion; Components: video\extract_audio
Source: "actions\extract_audio_to_ogg.exe"; DestDir: "{app}\actions"; Flags: ignoreversion; Components: video\extract_audio
Source: "actions\extract_audio_picker.exe"; DestDir: "{app}\actions"; Flags: ignoreversion; Components: video\extract_audio
Source: "actions\create_gif.exe"; DestDir: "{app}\actions"; Flags: ignoreversion; Components: video\create_gif
Source: "actions\convert_video_picker.exe"; DestDir: "{app}\actions"; Flags: ignoreversion; Components: video\convert
Source: "actions\resize_video.exe"; DestDir: "{app}\actions"; Flags: ignoreversion; Components: video\resize_video
Source: "actions\crop_video.exe"; DestDir: "{app}\actions"; Flags: ignoreversion; Components: video\crop_video
Source: "actions\rotate_video.exe"; DestDir: "{app}\actions"; Flags: ignoreversion; Components: video\rotate
Source: "actions\compress_video.exe"; DestDir: "{app}\actions"; Flags: ignoreversion; Components: video\compress
Source: "actions\change_video_speed.exe"; DestDir: "{app}\actions"; Flags: ignoreversion; Components: video\change_speed
Source: "actions\media_info.exe"; DestDir: "{app}\actions"; Flags: ignoreversion; Components: video\media_info audio\media_info image\media_info
Source: "actions\cut_audio.exe"; DestDir: "{app}\actions"; Flags: ignoreversion; Components: audio\cut_audio
Source: "actions\change_audio_speed.exe"; DestDir: "{app}\actions"; Flags: ignoreversion; Components: audio\change_speed
Source: "actions\reverse_audio.exe"; DestDir: "{app}\actions"; Flags: ignoreversion; Components: audio\reverse
Source: "actions\compress_audio.exe"; DestDir: "{app}\actions"; Flags: ignoreversion; Components: audio\compress
Source: "actions\change_audio_pitch.ps1"; DestDir: "{app}\actions"; Flags: ignoreversion; Components: audio\change_pitch
Source: "actions\change_audio_pitch.exe"; DestDir: "{app}\actions"; Flags: ignoreversion; Components: audio\change_pitch
Source: "actions\convert_audio_to_mp3.exe"; DestDir: "{app}\actions"; Flags: ignoreversion; Components: audio\convert
Source: "actions\convert_audio_to_wav.exe"; DestDir: "{app}\actions"; Flags: ignoreversion; Components: audio\convert
Source: "actions\convert_audio_to_flac.exe"; DestDir: "{app}\actions"; Flags: ignoreversion; Components: audio\convert
Source: "actions\convert_audio_to_m4a.exe"; DestDir: "{app}\actions"; Flags: ignoreversion; Components: audio\convert
Source: "actions\convert_audio_to_ogg.exe"; DestDir: "{app}\actions"; Flags: ignoreversion; Components: audio\convert
Source: "actions\convert_audio_picker.exe"; DestDir: "{app}\actions"; Flags: ignoreversion; Components: audio\convert
Source: "actions\resize_image.exe"; DestDir: "{app}\actions"; Flags: ignoreversion; Components: image\resize_image
Source: "actions\image_to_pdf.exe"; DestDir: "{app}\actions"; Flags: ignoreversion; Components: image\image_to_pdf
Source: "actions\image_to_pdf.exe.config"; DestDir: "{app}\actions"; Flags: ignoreversion; Components: image\image_to_pdf
Source: "actions\convert_image_to_png.exe"; DestDir: "{app}\actions"; Flags: ignoreversion; Components: image\convert
Source: "actions\convert_image_to_jpg.exe"; DestDir: "{app}\actions"; Flags: ignoreversion; Components: image\convert
Source: "actions\convert_image_to_webp.exe"; DestDir: "{app}\actions"; Flags: ignoreversion; Components: image\convert
Source: "actions\convert_image_to_bmp.exe"; DestDir: "{app}\actions"; Flags: ignoreversion; Components: image\convert
Source: "actions\convert_image_picker.exe"; DestDir: "{app}\actions"; Flags: ignoreversion; Components: image\convert
Source: "actions\compress_image.exe"; DestDir: "{app}\actions"; Flags: ignoreversion; Components: image\compress
Source: "actions\flip_image.exe"; DestDir: "{app}\actions"; Flags: ignoreversion; Components: image\flip
Source: "actions\crop_image.exe"; DestDir: "{app}\actions"; Flags: ignoreversion; Components: image\crop
Source: "actions\convert_icon.exe"; DestDir: "{app}\actions"; Flags: ignoreversion; Components: image\icon
Source: "tools\pdf\PdfSharp-gdi.dll"; DestDir: "{app}\tools\pdf"; Flags: ignoreversion; Components: image\image_to_pdf
Source: "tools\pdf\PdfSharp.Shared.dll"; DestDir: "{app}\tools\pdf"; Flags: ignoreversion; Components: image\image_to_pdf
Source: "tools\pdf\PdfSharp.System.dll"; DestDir: "{app}\tools\pdf"; Flags: ignoreversion; Components: image\image_to_pdf
Source: "tools\pdf\PdfSharp.Cryptography.dll"; DestDir: "{app}\tools\pdf"; Flags: ignoreversion; Components: image\image_to_pdf
Source: "tools\pdf\Microsoft.Extensions.Logging.Abstractions.dll"; DestDir: "{app}\tools\pdf"; Flags: ignoreversion; Components: image\image_to_pdf
Source: "tools\pdf\Microsoft.Extensions.DependencyInjection.Abstractions.dll"; DestDir: "{app}\tools\pdf"; Flags: ignoreversion; Components: image\image_to_pdf
Source: "tools\pdf\Microsoft.Bcl.AsyncInterfaces.dll"; DestDir: "{app}\tools\pdf"; Flags: ignoreversion; Components: image\image_to_pdf
Source: "tools\pdf\System.Threading.Tasks.Extensions.dll"; DestDir: "{app}\tools\pdf"; Flags: ignoreversion; Components: image\image_to_pdf
Source: "tools\pdf\System.Memory.dll"; DestDir: "{app}\tools\pdf"; Flags: ignoreversion; Components: image\image_to_pdf
Source: "tools\pdf\System.Buffers.dll"; DestDir: "{app}\tools\pdf"; Flags: ignoreversion; Components: image\image_to_pdf
Source: "tools\pdf\System.Runtime.CompilerServices.Unsafe.dll"; DestDir: "{app}\tools\pdf"; Flags: ignoreversion; Components: image\image_to_pdf
Source: "tools\pdf\System.Numerics.Vectors.dll"; DestDir: "{app}\tools\pdf"; Flags: ignoreversion; Components: image\image_to_pdf
Source: "tools\pdf\System.Security.Cryptography.Pkcs.dll"; DestDir: "{app}\tools\pdf"; Flags: ignoreversion; Components: image\image_to_pdf

Source: "tools\ffmpeg\ffmpeg.exe"; DestDir: "{app}\tools\ffmpeg"; Flags: ignoreversion; Components: video\cut_video video\interpolate video\remove_audio video\extract_frames video\extract_audio video\create_gif video\resize_video video\change_speed video\crop_video video\rotate video\compress video\convert audio\cut_audio audio\change_speed audio\reverse audio\compress audio\change_pitch audio\convert image\convert image\compress image\flip image\crop image\icon
Source: "tools\ffmpeg\ffprobe.exe"; DestDir: "{app}\tools\ffmpeg"; Flags: ignoreversion; Components: video\cut_video video\interpolate video\remove_audio video\extract_frames video\extract_audio video\create_gif video\resize_video video\change_speed video\crop_video video\rotate video\compress video\convert video\media_info audio\cut_audio audio\change_speed audio\reverse audio\compress audio\change_pitch audio\convert audio\media_info image\media_info
Source: "tools\icons\ffactions.ico"; DestDir: "{app}\tools\icons"; DestName: "ffactions.ico"; Flags: ignoreversion; Components: video\cut_video video\interpolate video\remove_audio video\extract_frames video\extract_audio video\create_gif video\resize_video video\change_speed video\crop_video video\rotate video\compress video\convert video\media_info audio\cut_audio audio\change_speed audio\reverse audio\compress audio\change_pitch audio\convert audio\media_info image\resize_image image\image_to_pdf image\convert image\compress image\flip image\crop image\icon image\media_info
Source: "tools\icons\icones menus\change.pitch_audio_icon.ico"; DestDir: "{app}\tools\icons\icones menus"; Flags: ignoreversion; Components: audio\change_pitch
Source: "tools\icons\icones menus\change.speed_audio_icon.ico"; DestDir: "{app}\tools\icons\icones menus"; Flags: ignoreversion; Components: video\change_speed audio\change_speed
Source: "tools\icons\icones menus\compress_video_image_audio_icon.ico"; DestDir: "{app}\tools\icons\icones menus"; Flags: ignoreversion; Components: video\compress audio\compress image\compress
Source: "tools\icons\icones menus\convert_audio_video_image_icon.ico"; DestDir: "{app}\tools\icons\icones menus"; Flags: ignoreversion; Components: video\convert audio\convert image\convert
Source: "tools\icons\icones menus\convert.icon_image_icon.ico"; DestDir: "{app}\tools\icons\icones menus"; Flags: ignoreversion; Components: image\icon
Source: "tools\icons\icones menus\create.gif_video_icon.ico"; DestDir: "{app}\tools\icons\icones menus"; Flags: ignoreversion; Components: video\create_gif
Source: "tools\icons\icones menus\crop_video_image_icon.ico"; DestDir: "{app}\tools\icons\icones menus"; Flags: ignoreversion; Components: video\crop_video image\crop
Source: "tools\icons\icones menus\cut_video_audio_icon.ico"; DestDir: "{app}\tools\icons\icones menus"; Flags: ignoreversion; Components: video\cut_video audio\cut_audio
Source: "tools\icons\icones menus\extract.frames_video_icon.ico"; DestDir: "{app}\tools\icons\icones menus"; Flags: ignoreversion; Components: video\extract_frames
Source: "tools\icons\icones menus\extract.audio_video_icon.ico"; DestDir: "{app}\tools\icons\icones menus"; Flags: ignoreversion; Components: video\extract_audio
Source: "tools\icons\icones menus\image.to.pdf_image_icon.ico"; DestDir: "{app}\tools\icons\icones menus"; Flags: ignoreversion; Components: image\image_to_pdf
Source: "tools\icons\icones menus\interpolate_video_icon.ico"; DestDir: "{app}\tools\icons\icones menus"; Flags: ignoreversion; Components: video\interpolate
Source: "tools\icons\icones menus\media.info_video_image_audio_icon.ico"; DestDir: "{app}\tools\icons\icones menus"; Flags: ignoreversion; Components: video\media_info audio\media_info image\media_info
Source: "tools\icons\icones menus\remove.audio_video_icon.ico"; DestDir: "{app}\tools\icons\icones menus"; Flags: ignoreversion; Components: video\remove_audio
Source: "tools\icons\icones menus\resize_image_video_icon.ico"; DestDir: "{app}\tools\icons\icones menus"; Flags: ignoreversion; Components: video\resize_video image\resize_image
Source: "tools\icons\icones menus\reverse.audio_audio_icon.ico"; DestDir: "{app}\tools\icons\icones menus"; Flags: ignoreversion; Components: audio\reverse
Source: "tools\icons\icones menus\rotate_video_image_icon.ico"; DestDir: "{app}\tools\icons\icones menus"; Flags: ignoreversion; Components: video\rotate image\flip
Source: "tools\icons\rotate.filp.menu\Rotate.left_icon.ico"; DestDir: "{app}\tools\icons\rotate.filp.menu"; Flags: ignoreversion; Components: video\rotate image\flip
Source: "tools\icons\rotate.filp.menu\Rotate.right_icon.ico"; DestDir: "{app}\tools\icons\rotate.filp.menu"; Flags: ignoreversion; Components: video\rotate image\flip
Source: "tools\icons\rotate.filp.menu\flip.horizontal_icon.ico"; DestDir: "{app}\tools\icons\rotate.filp.menu"; Flags: ignoreversion; Components: video\rotate image\flip
Source: "tools\icons\rotate.filp.menu\filp.vertical_icon.ico"; DestDir: "{app}\tools\icons\rotate.filp.menu"; Flags: ignoreversion; Components: video\rotate image\flip
Source: "tools\icons\image.to.pdf.menu\add.image_icon.ico"; DestDir: "{app}\tools\icons\image.to.pdf.menu"; Flags: ignoreversion; Components: image\image_to_pdf
Source: "tools\icons\image.to.pdf.menu\bring.forward_icon.ico"; DestDir: "{app}\tools\icons\image.to.pdf.menu"; Flags: ignoreversion; Components: image\image_to_pdf
Source: "tools\icons\image.to.pdf.menu\Bring.to.front_icon.ico"; DestDir: "{app}\tools\icons\image.to.pdf.menu"; Flags: ignoreversion; Components: image\image_to_pdf
Source: "tools\icons\image.to.pdf.menu\center_icon.ico"; DestDir: "{app}\tools\icons\image.to.pdf.menu"; Flags: ignoreversion; Components: image\image_to_pdf
Source: "tools\icons\image.to.pdf.menu\Crop_icon.ico"; DestDir: "{app}\tools\icons\image.to.pdf.menu"; Flags: ignoreversion; Components: image\image_to_pdf
Source: "tools\icons\image.to.pdf.menu\export_icon.ico"; DestDir: "{app}\tools\icons\image.to.pdf.menu"; Flags: ignoreversion; Components: image\image_to_pdf
Source: "tools\icons\image.to.pdf.menu\fit.to.page_icon.ico"; DestDir: "{app}\tools\icons\image.to.pdf.menu"; Flags: ignoreversion; Components: image\image_to_pdf
Source: "tools\icons\image.to.pdf.menu\print_icon.ico"; DestDir: "{app}\tools\icons\image.to.pdf.menu"; Flags: ignoreversion; Components: image\image_to_pdf
Source: "tools\icons\image.to.pdf.menu\send.backward_icon.ico"; DestDir: "{app}\tools\icons\image.to.pdf.menu"; Flags: ignoreversion; Components: image\image_to_pdf
Source: "tools\icons\image.to.pdf.menu\send.to.back_icon.ico"; DestDir: "{app}\tools\icons\image.to.pdf.menu"; Flags: ignoreversion; Components: image\image_to_pdf

[InstallDelete]
Type: files; Name: "{app}\actions\cut_by_frame.exe"
Type: files; Name: "{app}\actions\cut_video.exe"
Type: files; Name: "{app}\actions\cut_by_time.exe"
Type: files; Name: "{app}\actions\interpolate.exe"
Type: files; Name: "{app}\actions\convert_to_mp4.exe"
Type: files; Name: "{app}\actions\convert_to_mkv.exe"
Type: files; Name: "{app}\actions\convert_to_avi.exe"
Type: files; Name: "{app}\actions\convert_to_mov.exe"
Type: files; Name: "{app}\actions\convert_to_webm.exe"
Type: files; Name: "{app}\actions\convert_to_m4v.exe"
Type: files; Name: "{app}\actions\remove_audio.exe"
Type: files; Name: "{app}\actions\extract_frames.exe"
Type: files; Name: "{app}\actions\extract_audio_to_mp3.exe"
Type: files; Name: "{app}\actions\extract_audio_to_wav.exe"
Type: files; Name: "{app}\actions\extract_audio_to_flac.exe"
Type: files; Name: "{app}\actions\extract_audio_to_m4a.exe"
Type: files; Name: "{app}\actions\extract_audio_to_ogg.exe"
Type: files; Name: "{app}\actions\extract_audio_picker.ps1"
Type: files; Name: "{app}\actions\extract_audio_picker.exe"
Type: files; Name: "{app}\actions\create_gif.exe"
Type: files; Name: "{app}\actions\convert_video_picker.ps1"
Type: files; Name: "{app}\actions\convert_video_picker.exe"
Type: files; Name: "{app}\actions\resize_video.exe"
Type: files; Name: "{app}\actions\crop_video.exe"
Type: files; Name: "{app}\actions\rotate_video.exe"
Type: files; Name: "{app}\actions\compress_video.exe"
Type: files; Name: "{app}\actions\change_video_speed.exe"
Type: files; Name: "{app}\actions\media_info.exe"
Type: files; Name: "{app}\actions\cut_audio.exe"
Type: files; Name: "{app}\actions\change_audio_speed.exe"
Type: files; Name: "{app}\actions\reverse_audio.exe"
Type: files; Name: "{app}\actions\compress_audio.exe"
Type: files; Name: "{app}\actions\change_audio_pitch.exe"
Type: files; Name: "{app}\actions\convert_audio_to_mp3.exe"
Type: files; Name: "{app}\actions\convert_audio_to_wav.exe"
Type: files; Name: "{app}\actions\convert_audio_to_flac.exe"
Type: files; Name: "{app}\actions\convert_audio_to_m4a.exe"
Type: files; Name: "{app}\actions\convert_audio_to_ogg.exe"
Type: files; Name: "{app}\actions\convert_audio_picker.ps1"
Type: files; Name: "{app}\actions\convert_audio_picker.exe"
Type: files; Name: "{app}\actions\resize_image.exe"
Type: files; Name: "{app}\actions\image_to_pdf.exe"
Type: files; Name: "{app}\actions\image_to_pdf.exe.config"
Type: files; Name: "{app}\actions\convert_image_to_png.exe"
Type: files; Name: "{app}\actions\convert_image_to_jpg.exe"
Type: files; Name: "{app}\actions\convert_image_to_webp.exe"
Type: files; Name: "{app}\actions\convert_image_to_bmp.exe"
Type: files; Name: "{app}\actions\convert_image_picker.ps1"
Type: files; Name: "{app}\actions\convert_image_picker.exe"
Type: files; Name: "{app}\actions\compress_image.exe"
Type: files; Name: "{app}\actions\flip_image.exe"
Type: files; Name: "{app}\actions\crop_image.exe"
Type: files; Name: "{app}\actions\convert_icon.exe"
Type: files; Name: "{app}\tools\pdf\PdfSharp-gdi.dll"
Type: files; Name: "{app}\tools\pdf\PdfSharp.Shared.dll"
Type: files; Name: "{app}\tools\pdf\PdfSharp.System.dll"
Type: files; Name: "{app}\tools\pdf\PdfSharp.Cryptography.dll"
Type: files; Name: "{app}\tools\pdf\Microsoft.Extensions.Logging.Abstractions.dll"
Type: files; Name: "{app}\tools\pdf\Microsoft.Extensions.DependencyInjection.Abstractions.dll"
Type: files; Name: "{app}\tools\pdf\Microsoft.Bcl.AsyncInterfaces.dll"
Type: files; Name: "{app}\tools\pdf\System.Threading.Tasks.Extensions.dll"
Type: files; Name: "{app}\tools\pdf\System.Memory.dll"
Type: files; Name: "{app}\tools\pdf\System.Buffers.dll"
Type: files; Name: "{app}\tools\pdf\System.Runtime.CompilerServices.Unsafe.dll"
Type: files; Name: "{app}\tools\pdf\System.Numerics.Vectors.dll"
Type: files; Name: "{app}\tools\pdf\System.Security.Cryptography.Pkcs.dll"
Type: files; Name: "{app}\tools\ffmpeg\ffmpeg.exe"
Type: files; Name: "{app}\tools\ffmpeg\ffprobe.exe"
Type: files; Name: "{app}\tools\icons\ffactions.ico"
Type: files; Name: "{app}\tools\icons\icones menus\change.pitch_audio_icon.ico"
Type: files; Name: "{app}\tools\icons\icones menus\change.speed_audio_icon.ico"
Type: files; Name: "{app}\tools\icons\icones menus\compress_video_image_audio_icon.ico"
Type: files; Name: "{app}\tools\icons\icones menus\convert_audio_video_image_icon.ico"
Type: files; Name: "{app}\tools\icons\icones menus\convert.icon_image_icon.ico"
Type: files; Name: "{app}\tools\icons\icones menus\create.gif_video_icon.ico"
Type: files; Name: "{app}\tools\icons\icones menus\crop_video_image_icon.ico"
Type: files; Name: "{app}\tools\icons\icones menus\cut_video_audio_icon.ico"
Type: files; Name: "{app}\tools\icons\icones menus\extract.frames_video_icon.ico"
Type: files; Name: "{app}\tools\icons\icones menus\extract.audio_video_icon.ico"
Type: files; Name: "{app}\tools\icons\icones menus\image.to.pdf_image_icon.ico"
Type: files; Name: "{app}\tools\icons\icones menus\interpolate_video_icon.ico"
Type: files; Name: "{app}\tools\icons\icones menus\media.info_video_image_audio_icon.ico"
Type: files; Name: "{app}\tools\icons\icones menus\remove.audio_video_icon.ico"
Type: files; Name: "{app}\tools\icons\icones menus\resize_image_video_icon.ico"
Type: files; Name: "{app}\tools\icons\icones menus\reverse.audio_audio_icon.ico"
Type: files; Name: "{app}\tools\icons\icones menus\rotate_video_image_icon.ico"
Type: files; Name: "{app}\tools\icons\rotate.filp.menu\Rotate.left_icon.ico"
Type: files; Name: "{app}\tools\icons\rotate.filp.menu\Rotate.right_icon.ico"
Type: files; Name: "{app}\tools\icons\rotate.filp.menu\flip.horizontal_icon.ico"
Type: files; Name: "{app}\tools\icons\rotate.filp.menu\filp.vertical_icon.ico"
Type: files; Name: "{app}\tools\icons\image.to.pdf.menu\add.image_icon.ico"
Type: files; Name: "{app}\tools\icons\image.to.pdf.menu\bring.forward_icon.ico"
Type: files; Name: "{app}\tools\icons\image.to.pdf.menu\Bring.to.front_icon.ico"
Type: files; Name: "{app}\tools\icons\image.to.pdf.menu\center_icon.ico"
Type: files; Name: "{app}\tools\icons\image.to.pdf.menu\Crop_icon.ico"
Type: files; Name: "{app}\tools\icons\image.to.pdf.menu\export_icon.ico"
Type: files; Name: "{app}\tools\icons\image.to.pdf.menu\fit.to.page_icon.ico"
Type: files; Name: "{app}\tools\icons\image.to.pdf.menu\print_icon.ico"
Type: files; Name: "{app}\tools\icons\image.to.pdf.menu\send.backward_icon.ico"
Type: files; Name: "{app}\tools\icons\image.to.pdf.menu\send.to.back_icon.ico"
Type: files; Name: "{app}\tools\repair_video_menus.ps1"
Type: files; Name: "{app}\tools\repair_audio_image_convert_menus.ps1"
Type: files; Name: "{app}\actions\_shared\ffcommon_encoding.ps1"
Type: files; Name: "{app}\actions\_shared\ffcommon_ui_helpers.ps1"

[UninstallDelete]
Type: files; Name: "{app}\actions\cut_by_frame.exe"
Type: files; Name: "{app}\actions\cut_by_time.exe"
Type: files; Name: "{app}\actions\audio_info.exe"
Type: files; Name: "{app}\actions\video_info.exe"
Type: files; Name: "{app}\actions\image_info.exe"
Type: files; Name: "{app}\actions\audio_info.ps1"
Type: files; Name: "{app}\actions\video_info.ps1"
Type: files; Name: "{app}\actions\image_info.ps1"
Type: files; Name: "{app}\actions\extract_audio_picker.ps1"
Type: files; Name: "{app}\actions\convert_video_picker.ps1"
Type: files; Name: "{app}\actions\convert_audio_picker.ps1"
Type: files; Name: "{app}\actions\convert_image_picker.ps1"
Type: files; Name: "{app}\tools\repair_video_menus.ps1"
Type: files; Name: "{app}\actions\_shared\ffcommon_encoding.ps1"
Type: files; Name: "{app}\actions\_shared\ffcommon_ui_helpers.ps1"

[Code]
var
  MaintenancePage: TInputOptionWizardPage;
  InstalledVersion: string;
  InstalledDir: string;
  InstalledUninstaller: string;
  PreviousComponents: string;
  IsInstalled: Boolean;
  CloseAfterUninstall: Boolean;

const
  UninstallKey = 'Software\Microsoft\Windows\CurrentVersion\Uninstall\FFActions_is1';
  FileAssociationsKey = 'Software\Classes\SystemFileAssociations';

function GetVersionPart(var Version: string): Integer;
var
  DotPos: Integer;
  Part: string;
begin
  DotPos := Pos('.', Version);
  if DotPos > 0 then
  begin
    Part := Copy(Version, 1, DotPos - 1);
    Delete(Version, 1, DotPos);
  end
  else
  begin
    Part := Version;
    Version := '';
  end;

  Result := StrToIntDef(Part, 0);
end;

function GetListItem(var ValueList: string): string;
var
  SeparatorPos: Integer;
begin
  SeparatorPos := Pos(',', ValueList);

  if SeparatorPos > 0 then
  begin
    Result := Copy(ValueList, 1, SeparatorPos - 1);
    Delete(ValueList, 1, SeparatorPos);
  end
  else
  begin
    Result := ValueList;
    ValueList := '';
  end;
end;

function ComponentListContains(const Components, ComponentName: string): Boolean;
var
  RemainingComponents: string;
begin
  Result := False;
  RemainingComponents := Components;

  while RemainingComponents <> '' do
  begin
    if GetListItem(RemainingComponents) = ComponentName then
    begin
      Result := True;
      Exit;
    end;
  end;
end;

function ComponentListHasPrefix(const Components, ComponentPrefix: string): Boolean;
var
  RemainingComponents: string;
  ComponentName: string;
begin
  Result := False;
  RemainingComponents := Components;

  while RemainingComponents <> '' do
  begin
    ComponentName := GetListItem(RemainingComponents);
    if Pos(ComponentPrefix, ComponentName) = 1 then
    begin
      Result := True;
      Exit;
    end;
  end;
end;

function CompareVersions(VersionA, VersionB: string): Integer;
var
  PartA: Integer;
  PartB: Integer;
begin
  Result := 0;

  while (VersionA <> '') or (VersionB <> '') do
  begin
    PartA := GetVersionPart(VersionA);
    PartB := GetVersionPart(VersionB);

    if PartA > PartB then
    begin
      Result := 1;
      Exit;
    end;

    if PartA < PartB then
    begin
      Result := -1;
      Exit;
    end;
  end;
end;

function QueryInstalledString(const ValueName: string; var Value: string): Boolean;
begin
  Result :=
    RegQueryStringValue(HKLM, UninstallKey, ValueName, Value) or
    RegQueryStringValue(HKCU, UninstallKey, ValueName, Value);
end;

function DetectInstalledVersion(): Boolean;
begin
  Result := QueryInstalledString('DisplayVersion', InstalledVersion);

  if Result then
  begin
    QueryInstalledString('InstallLocation', InstalledDir);
    if InstalledDir = '' then
    begin
      QueryInstalledString('Inno Setup: App Path', InstalledDir);
    end;

    QueryInstalledString('UninstallString', InstalledUninstaller);
  end;
end;

function AddComponentIfFileExists(
  const Components, ComponentName, RelativeFileName: string): string;
begin
  Result := Components;
  if FileExists(AddBackslash(InstalledDir) + RelativeFileName) then
  begin
    if Result <> '' then
    begin
      Result := Result + ',';
    end;
    Result := Result + ComponentName;
  end;
end;

function RegistryKeyExistsInEitherHive(const Subkey: string): Boolean;
begin
  Result := RegKeyExists(HKLM, Subkey) or RegKeyExists(HKCU, Subkey);
end;

function AddComponentIfMissing(const Components, ComponentName: string): string;
begin
  Result := Components;

  if ComponentListContains(Result, ComponentName) then
  begin
    Exit;
  end;

  if Result <> '' then
  begin
    Result := Result + ',';
  end;

  Result := Result + ComponentName;
end;

function AddComponentIfRegistryKeyExists(
  const Components, ComponentName, RegistrySubkey: string): string;
begin
  Result := Components;

  if RegistryKeyExistsInEitherHive(RegistrySubkey) then
  begin
    Result := AddComponentIfMissing(Result, ComponentName);
  end;
end;

function DetectInstalledComponentsFromFiles(): string;
begin
  Result := '';

  if InstalledDir = '' then
  begin
    Exit;
  end;

  Result := AddComponentIfFileExists(Result, 'video\cut_video', 'actions\cut_video.exe');
  Result := AddComponentIfFileExists(Result, 'video\interpolate', 'actions\interpolate.exe');
  Result := AddComponentIfFileExists(Result, 'video\remove_audio', 'actions\remove_audio.exe');
  Result := AddComponentIfFileExists(Result, 'video\extract_frames', 'actions\extract_frames.exe');
  Result := AddComponentIfFileExists(Result, 'video\extract_audio', 'actions\extract_audio_picker.exe');
  Result := AddComponentIfFileExists(Result, 'video\create_gif', 'actions\create_gif.exe');
  Result := AddComponentIfFileExists(Result, 'video\resize_video', 'actions\resize_video.exe');
  Result := AddComponentIfFileExists(Result, 'video\change_speed', 'actions\change_video_speed.exe');
  Result := AddComponentIfFileExists(Result, 'video\crop_video', 'actions\crop_video.exe');
  Result := AddComponentIfFileExists(Result, 'video\rotate', 'actions\rotate_video.exe');
  Result := AddComponentIfFileExists(Result, 'video\compress', 'actions\compress_video.exe');
  Result := AddComponentIfFileExists(Result, 'video\convert', 'actions\convert_video_picker.exe');
  Result := AddComponentIfRegistryKeyExists(
    Result,
    'video\media_info',
    'Software\Classes\SystemFileAssociations\.mp4\shell\FFActions\shell\media_info\command');

  Result := AddComponentIfFileExists(Result, 'audio\cut_audio', 'actions\cut_audio.exe');
  Result := AddComponentIfFileExists(Result, 'audio\change_speed', 'actions\change_audio_speed.exe');
  Result := AddComponentIfFileExists(Result, 'audio\reverse', 'actions\reverse_audio.exe');
  Result := AddComponentIfFileExists(Result, 'audio\compress', 'actions\compress_audio.exe');
  Result := AddComponentIfFileExists(Result, 'audio\change_pitch', 'actions\change_audio_pitch.exe');
  Result := AddComponentIfFileExists(Result, 'audio\convert', 'actions\convert_audio_picker.exe');
  Result := AddComponentIfRegistryKeyExists(
    Result,
    'audio\media_info',
    'Software\Classes\SystemFileAssociations\.wav\shell\FFActions\shell\media_info\command');

  Result := AddComponentIfFileExists(Result, 'image\resize_image', 'actions\resize_image.exe');
  Result := AddComponentIfFileExists(Result, 'image\image_to_pdf', 'actions\image_to_pdf.exe');
  Result := AddComponentIfFileExists(Result, 'image\convert', 'actions\convert_image_picker.exe');
  Result := AddComponentIfFileExists(Result, 'image\compress', 'actions\compress_image.exe');
  Result := AddComponentIfFileExists(Result, 'image\flip', 'actions\flip_image.exe');
  Result := AddComponentIfFileExists(Result, 'image\crop', 'actions\crop_image.exe');
  Result := AddComponentIfFileExists(Result, 'image\icon', 'actions\convert_icon.exe');
  Result := AddComponentIfRegistryKeyExists(
    Result,
    'image\media_info',
    'Software\Classes\SystemFileAssociations\.png\shell\FFActions\shell\media_info\command');
end;

function AddMediaInfoForSelectedFamilies(const Components: string): string;
begin
  Result := Components;

  if ComponentListHasPrefix(Result, 'video\') then
  begin
    Result := AddComponentIfMissing(Result, 'video\media_info');
  end;

  if ComponentListHasPrefix(Result, 'audio\') then
  begin
    Result := AddComponentIfMissing(Result, 'audio\media_info');
  end;

  if ComponentListHasPrefix(Result, 'image\') then
  begin
    Result := AddComponentIfMissing(Result, 'image\media_info');
  end;
end;

function ExtractUninstallerPath(const UninstallString: string): string;
var
  SpacePos: Integer;
  Remainder: string;
begin
  Result := UninstallString;

  if Result = '' then
  begin
    Exit;
  end;

  if Copy(Result, 1, 1) = '"' then
  begin
    Remainder := Copy(Result, 2, Length(Result) - 1);
    SpacePos := Pos('"', Remainder);
    if SpacePos > 0 then
    begin
      Result := Copy(Remainder, 1, SpacePos - 1);
    end;
  end
  else
  begin
    SpacePos := Pos(' ', Result);
    if SpacePos > 0 then
    begin
      Result := Copy(Result, 1, SpacePos - 1);
    end;
  end;
end;

function LaunchInstalledUninstaller(): Boolean;
var
  UninstallerPath: string;
  ResultCode: Integer;
begin
  Result := False;
  UninstallerPath := ExtractUninstallerPath(InstalledUninstaller);

  if (UninstallerPath = '') or not FileExists(UninstallerPath) then
  begin
    MsgBox(
      'The FFActions uninstaller could not be found.' + #13#10 +
      'You can still uninstall it from Windows settings if needed.',
      mbError,
      MB_OK);
    Exit;
  end;

  Result := Exec(UninstallerPath, '', '', SW_SHOW, ewNoWait, ResultCode);
end;

function GetSelectedComponentNames(): string;
begin
  Result := WizardSelectedComponents(False);
end;

procedure SelectPreviousComponents;
begin
  if PreviousComponents <> '' then
  begin
    WizardSelectComponents(PreviousComponents);
  end;
end;

procedure CleanupContextMenuKeysForHive(const Hive: Integer);
var
  Extensions: TArrayOfString;
  Index: Integer;
begin
  if not RegGetSubkeyNames(Hive, FileAssociationsKey, Extensions) then
  begin
    Exit;
  end;

  for Index := 0 to GetArrayLength(Extensions) - 1 do
  begin
    RegDeleteKeyIncludingSubkeys(
      Hive, FileAssociationsKey + '\' + Extensions[Index] + '\shell\FFActions');
  end;
end;

procedure CleanupContextMenuKeys;
begin
  CleanupContextMenuKeysForHive(HKCU);
  CleanupContextMenuKeysForHive(HKLM);
end;

procedure EnsureFFActionsRootForHive(const Hive: Integer; const Ext: string);
var
  KeyPath: string;
begin
  KeyPath := FileAssociationsKey + '\' + Ext + '\shell\FFActions';
  RegWriteStringValue(Hive, KeyPath, 'MUIVerb', 'FFActions');
  RegWriteStringValue(Hive, KeyPath, 'SubCommands', '');
  RegWriteStringValue(Hive, KeyPath, 'Icon', ExpandConstant('{app}\tools\icons\ffactions.ico'));
end;

procedure ConfigureActionMenuForHive(
  const Hive: Integer; const Ext, VerbName, LabelText, ExeName, IconFileName: string;
  const CommandFlags: Cardinal);
var
  KeyPath: string;
  CommandValue: string;
begin
  EnsureFFActionsRootForHive(Hive, Ext);
  KeyPath := FileAssociationsKey + '\' + Ext + '\shell\FFActions\shell\' + VerbName;
  RegDeleteKeyIncludingSubkeys(Hive, KeyPath);
  RegWriteStringValue(Hive, KeyPath, 'MUIVerb', LabelText);
  if IconFileName <> '' then
  begin
    RegWriteStringValue(
      Hive, KeyPath, 'Icon', ExpandConstant('{app}\tools\icons\icones menus\' + IconFileName));
  end;

  if CommandFlags <> 0 then
  begin
    RegWriteDWordValue(Hive, KeyPath, 'CommandFlags', CommandFlags);
  end;

  CommandValue := '"' + ExpandConstant('{app}\actions\' + ExeName) + '" "%1"';
  RegWriteStringValue(Hive, KeyPath + '\command', '', CommandValue);
end;

procedure ApplyActionMenuList(
  const Extensions, VerbName, LabelText, ExeName, IconFileName: string;
  const CommandFlags: Cardinal; const AllUsers: Boolean);
var
  RemainingExtensions: string;
  Extension: string;
begin
  RemainingExtensions := Extensions;

  while RemainingExtensions <> '' do
  begin
    Extension := GetListItem(RemainingExtensions);
    ConfigureActionMenuForHive(
      HKCU, Extension, VerbName, LabelText, ExeName, IconFileName, CommandFlags);

    if AllUsers and IsAdminInstallMode then
    begin
      ConfigureActionMenuForHive(
        HKLM, Extension, VerbName, LabelText, ExeName, IconFileName, CommandFlags);
    end;
  end;
end;

#include ContextMenuInclude

function InitializeSetup(): Boolean;
begin
  Result := True;
  IsInstalled := DetectInstalledVersion();

  if IsInstalled and
    (CompareVersions(InstalledVersion, '{#SetupSetting("AppVersion")}') > 0) then
  begin
    MsgBox(
      'A newer version of FFActions is already installed (' +
      InstalledVersion + ').' + #13#10 +
      'This {#InstallerVersionText} installer cannot downgrade it.',
      mbError,
      MB_OK);
    Result := False;
  end;
end;

procedure InitializeWizard;
var
  PageCaption: string;
  PageDescription: string;
  PageSubCaption: string;
begin
  if not IsInstalled then
  begin
    Exit;
  end;

  PreviousComponents := GetPreviousData('SelectedComponents', '');
  if PreviousComponents = '' then
  begin
    PreviousComponents := DetectInstalledComponentsFromFiles();
  end;
  PreviousComponents := AddMediaInfoForSelectedFamilies(PreviousComponents);
  SelectPreviousComponents;

  if CompareVersions(InstalledVersion, '{#SetupSetting("AppVersion")}') = 0 then
  begin
    PageCaption := 'FFActions {#InstallerVersionText} is already installed';
    PageDescription := 'Choose what you want to do.';
    PageSubCaption :=
      'You can modify the installed modules or run the uninstaller.';
    MaintenancePage := CreateInputOptionPage(
      wpWelcome,
      PageCaption,
      PageDescription,
      PageSubCaption,
      True,
      False);
    MaintenancePage.Add('Modify installed modules');
    MaintenancePage.Add('Uninstall FFActions');
  end
  else
  begin
    PageCaption := 'Update FFActions';
    PageDescription :=
      'FFActions ' + InstalledVersion + ' is already installed.';
    PageSubCaption :=
      'You can update to {#InstallerVersionText} and adjust the installed modules, or run the uninstaller.';
    MaintenancePage := CreateInputOptionPage(
      wpWelcome,
      PageCaption,
      PageDescription,
      PageSubCaption,
      True,
      False);
    MaintenancePage.Add('Update to {#InstallerVersionText}');
    MaintenancePage.Add('Uninstall FFActions');
  end;

  MaintenancePage.Values[0] := True;
end;

function NextButtonClick(CurPageID: Integer): Boolean;
begin
  Result := True;

  if IsInstalled and (MaintenancePage <> nil) and
    (CurPageID = MaintenancePage.ID) then
  begin
    if MaintenancePage.Values[1] then
    begin
      if LaunchInstalledUninstaller() then
      begin
        CloseAfterUninstall := True;
        Result := False;
        WizardForm.Close;
      end
      else
      begin
        Result := False;
      end;
    end
    else
    begin
      SelectPreviousComponents;
    end;
  end;
end;

function ShouldSkipPage(PageID: Integer): Boolean;
begin
  Result := False;

  if IsInstalled and (PageID = wpSelectDir) then
  begin
    Result := True;
  end;
end;

procedure RegisterPreviousData(PreviousDataKey: Integer);
begin
  SetPreviousData(PreviousDataKey, 'SelectedComponents', GetSelectedComponentNames());
end;

procedure CancelButtonClick(CurPageID: Integer; var Cancel, Confirm: Boolean);
begin
  if CloseAfterUninstall then
  begin
    Confirm := False;
  end;
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssInstall then
  begin
    CleanupContextMenuKeys;
  end;

  if CurStep = ssPostInstall then
  begin
    ApplyContextMenus;
  end;
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  if CurUninstallStep = usUninstall then
  begin
    CleanupContextMenuKeys;
  end;
end;
