require "test_helper"

class AlarmSmsRendererTest < ActiveSupport::TestCase
  test "renders a pt-BR body with NAILA prefix and severity label" do
    alarm = alarms(:flood_alert_belem)
    body = AlarmSmsRenderer.render(alarm, 3)

    assert body.start_with?("[NAILA]"), "expected body to start with [NAILA], got: #{body}"
    assert_includes body, "Alerta Máximo"
    assert_includes body, alarm.name
    assert_includes body, "Acesse o painel."
  end

  test "body stays under 160 chars even for long alarm names" do
    alarm = alarms(:flood_alert_belem)
    alarm.name = "A" * 200
    body = AlarmSmsRenderer.render(alarm, 4)

    assert_operator body.length, :<=, 160, "body was #{body.length} chars: #{body}"
    assert_includes body, "Emergência"
  end

  test "maps each severity to the correct pt-BR label" do
    alarm = alarms(:flood_alert_belem)

    assert_includes AlarmSmsRenderer.render(alarm, 1), "Atenção"
    assert_includes AlarmSmsRenderer.render(alarm, 2), "Alerta"
    assert_includes AlarmSmsRenderer.render(alarm, 3), "Alerta Máximo"
    assert_includes AlarmSmsRenderer.render(alarm, 4), "Emergência"
  end
end
