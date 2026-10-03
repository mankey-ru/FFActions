1. ~~провести работу по tmp/cpu-patch~~ (0e0ae81, 217f54a)
2. продумать тестовые/дебаг прогоны для, взять для прогона tmp/Le-Accelerator-2017-Official-Trailer-1.mp4
   - UI actions (cut_video и др.) гонять через UI Automation: элементы искать по имени (Edit = следующий элемент после label "Start frame"/"End frame"), кликать по `BoundingRectangle` + `SetProcessDPIAware`. ControlType не использовать: UIA отдаёт все контролы как `Pane` (и из PS 5.1, и из PS 7). В WinForms TextBox `^a` вставляет литерал `a`, выделять через `{HOME}+{END}`
   - `dev/smoke_test.ps1`: действия без UI (exe и `.ps1`), цепочки пикеров через UIA (`BM_CLICK`), проба PDF, сверка меню `FFActionsDev`; медиа генерирует сам через ffmpeg (lavfi). Действия с UI (cut_video и др.) пока не покрыты
3. AMD AMF для Radeon: добавить в encoding plans видео-actions ветку `h264_amf` (проба одним кадром, как `Test-NvencAvailable`), порядок NVENC -> AMF -> CPU. Bundled ffmpeg 8.1 уже содержит `h264_amf`/`hevc_amf`/`av1_amf`, на Ryzen APU проверено: работает
4. Продумать установку не в program files, а в appdata или куда там сейчас принято ставить
   - ~~`FFActions.iss` ссылается на `actions\image_to_pdf.exe.config`, а ps2exe 1.0.18 его больше не генерирует -> сборка установщика упадёт. Выяснить, что в нём было и нужен ли он (в локальной установке 1.4.1 image-компоненты не стояли, взять можно из установщика upstream release 1.4.1)~~ (be8fa99): это binding redirects для `Microsoft.Extensions.*`, без них exe не создаёт PDF; файл взят из upstream 1.4.1 и закоммичен
5. ~~иметь возможность тестировать (запускать отдельные команды прямо из проекта)~~ (f5cc612, 5c38010)
   - собранные exe из проекта уже запускаются через ПКМ-меню `FFActionsDev`: `dev/dev_menu.ps1`, раскладка общая с инсталлятором в `dev/context_menu.psd1`
   - ~~запуск сгенерированных `actions\*.ps1` без сборки exe (как описано в README) не найдёт ffmpeg: `Get-AppRoot` берёт путь процесса, а под `powershell.exe -File` это `System32\WindowsPowerShell`, а не проект~~ (5c38010): скрипты генерируются через `build_all.ps1 -ScriptsOnly`, семейства convert/extract запускаются с `-ActionName`
6. идея: переход на PS7 - плюсы и минусы
7. идея: выборосить image_to_pdf.exe и конвертацию картинок в ПДФ в целом
8. идея - добавление профайлов в конвертацию видео, т.е. профайлы конвертации видео (опции ffmpeg) можно будет хранить в конфиге
9. добавить в поддерживаемые форматы видео MTS
