require "test_helper"

class AlarmSmsRendererTest < ActiveSupport::TestCase
  test "renders a pt-BR body with NAILA prefix and severity label" do
    alarm = alarms(:flood_alert_belem)
    body = AlarmSmsRenderer.render(alarm, 3)

    assert body.start_with?("[NAILA]"), "expected body to start with [NAILA], got: #{body}"
    assert_includes body, "Alarme"
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
    assert_includes AlarmSmsRenderer.render(alarm, 3), "Alarme"
    assert_includes AlarmSmsRenderer.render(alarm, 4), "Emergência"
  end

  test "frames as escalating when previous_severity is lower" do
    alarm = alarms(:flood_alert_belem)
    body = AlarmSmsRenderer.render(alarm, 3, previous_severity: 2)
    assert_includes body, "Subiu para Alarme"
  end

  test "frames as de-escalating when previous_severity is higher" do
    alarm = alarms(:flood_alert_belem)
    body = AlarmSmsRenderer.render(alarm, 2, previous_severity: 3)
    assert_includes body, "Desceu para Alerta"
  end

  test "stays plain when previous_severity is unknown" do
    alarm = alarms(:flood_alert_belem)
    body = AlarmSmsRenderer.render(alarm, 3)
    assert_includes body, "[NAILA] Alarme:"
  end

  test "renders a distinct resolved body for severity 0" do
    alarm = alarms(:flood_alert_belem)
    body = AlarmSmsRenderer.render(alarm, 0, previous_severity: 3)
    assert_includes body, "Resolvido"
    assert_includes body, "Vigilância"
    assert_operator body.length, :<=, 160
  end
end
