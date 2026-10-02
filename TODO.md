1. ~~провести работу по tmp/cpu-patch~~ (0e0ae81, 217f54a)
2. продумать тестовые/дебаг прогоны для, взять для прогона tmp/Le-Accelerator-2017-Official-Trailer-1.mp4
   - UI actions (cut_video и др.) гонять через UI Automation: элементы искать по имени (Edit = следующий элемент после label "Start frame"/"End frame"), кликать по `BoundingRectangle` + `SetProcessDPIAware`. ControlType не использовать: UIA отдаёт все контролы как `Pane` (и из PS 5.1, и из PS 7). В WinForms TextBox `^a` вставляет литерал `a`, выделять через `{HOME}+{END}`
3. AMD AMF для Radeon: добавить в encoding plans видео-actions ветку `h264_amf` (проба одним кадром, как `Test-NvencAvailable`), порядок NVENC -> AMF -> CPU. Bundled ffmpeg 8.1 уже содержит `h264_amf`/`hevc_amf`/`av1_amf`, на Ryzen APU проверено: работает
4. Продумать установку не в program files, а в appdata или куда там сейчас принято ставить
   - `FFActions.iss` ссылается на `actions\image_to_pdf.exe.config`, а ps2exe 1.0.18 его больше не генерирует -> сборка установщика упадёт. Выяснить, что в нём было и нужен ли он (в локальной установке 1.4.1 image-компоненты не стояли, взять можно из установщика upstream release 1.4.1)
5. иметь возможность тестировать (запускать отдельные команды прямо из проекта)
6. рассмотреть переход на PS7 - плюсы и минусы
