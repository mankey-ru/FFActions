# Layout of the FFActionsDev context menu registered by tools\dev_menu.ps1.
# Item order here is the order in the Explorer submenu. Re-run the script after editing.
#   Exe        - file name in actions\
#   Icon       - file name in tools\icons\icones menus\ (optional)
#   Extensions - per-item override of the family extensions (optional)
# Default order mirrors the menu produced by FFActions.iss.
@{
    Families = @(
        @{
            Name       = 'video'
            Extensions = @('.mp4', '.mkv', '.avi', '.mov', '.webm', '.m4v')
            Items      = @(
                @{ Label = 'resize video';   Exe = 'resize_video.exe';         Icon = 'resize_image_video_icon.ico' }
                @{ Label = 'change speed';   Exe = 'change_video_speed.exe';   Icon = 'change.speed_audio_icon.ico' }
                @{ Label = 'compress video'; Exe = 'compress_video.exe';       Icon = 'compress_video_image_audio_icon.ico' }
                @{ Label = 'convert';        Exe = 'convert_video_picker.exe'; Icon = 'convert_audio_video_image_icon.ico' }
                @{ Label = 'create gif';     Exe = 'create_gif.exe';           Icon = 'create.gif_video_icon.ico' }
                @{ Label = 'crop video';     Exe = 'crop_video.exe';           Icon = 'crop_video_image_icon.ico' }
                @{ Label = 'cut video';      Exe = 'cut_video.exe';            Icon = 'cut_video_audio_icon.ico' }
                @{ Label = 'extract audio';  Exe = 'extract_audio_picker.exe'; Icon = 'extract.audio_video_icon.ico' }
                @{ Label = 'extract frames'; Exe = 'extract_frames.exe';       Icon = 'extract.frames_video_icon.ico' }
                @{ Label = 'interpolate';    Exe = 'interpolate.exe';          Icon = 'interpolate_video_icon.ico' }
                @{ Label = 'remove audio';   Exe = 'remove_audio.exe';         Icon = 'remove.audio_video_icon.ico' }
                @{ Label = 'rotate / flip';  Exe = 'rotate_video.exe';         Icon = 'rotate_video_image_icon.ico' }
                @{ Label = 'media info';     Exe = 'media_info.exe';           Icon = 'media.info_video_image_audio_icon.ico' }
            )
        }
        @{
            Name       = 'audio'
            Extensions = @('.wav', '.mp3', '.flac', '.m4a', '.ogg')
            Items      = @(
                @{ Label = 'change pitch';   Exe = 'change_audio_pitch.exe';   Icon = 'change.pitch_audio_icon.ico' }
                @{ Label = 'change speed';   Exe = 'change_audio_speed.exe';   Icon = 'change.speed_audio_icon.ico' }
                @{ Label = 'compress audio'; Exe = 'compress_audio.exe';       Icon = 'compress_video_image_audio_icon.ico' }
                @{ Label = 'convert';        Exe = 'convert_audio_picker.exe'; Icon = 'convert_audio_video_image_icon.ico' }
                @{ Label = 'cut audio';      Exe = 'cut_audio.exe';            Icon = 'cut_video_audio_icon.ico' }
                @{ Label = 'reverse audio';  Exe = 'reverse_audio.exe';        Icon = 'reverse.audio_audio_icon.ico' }
                @{ Label = 'media info';     Exe = 'media_info.exe';           Icon = 'media.info_video_image_audio_icon.ico' }
            )
        }
        @{
            Name       = 'image'
            Extensions = @('.png', '.jpg', '.jpeg', '.bmp', '.webp')
            Items      = @(
                @{ Label = 'compress image';  Exe = 'compress_image.exe';       Icon = 'compress_video_image_audio_icon.ico' }
                @{ Label = 'convert';         Exe = 'convert_image_picker.exe'; Icon = 'convert_audio_video_image_icon.ico' }
                @{ Label = 'convert to icon'; Exe = 'convert_icon.exe';         Icon = 'convert.icon_image_icon.ico' }
                @{ Label = 'crop image';      Exe = 'crop_image.exe';           Icon = 'crop_video_image_icon.ico' }
                @{ Label = 'rotate / flip';   Exe = 'flip_image.exe';           Icon = 'rotate_video_image_icon.ico' }
                @{ Label = 'image to pdf';    Exe = 'image_to_pdf.exe';         Icon = 'image.to.pdf_image_icon.ico'; Extensions = @('.png', '.jpg', '.jpeg', '.bmp') }
                @{ Label = 'resize image';    Exe = 'resize_image.exe';         Icon = 'resize_image_video_icon.ico' }
                @{ Label = 'media info';      Exe = 'media_info.exe';           Icon = 'media.info_video_image_audio_icon.ico' }
            )
        }
    )
}
