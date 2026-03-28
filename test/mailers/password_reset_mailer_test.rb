require "test_helper"

class PasswordResetMailerTest < ActionMailer::TestCase
  test "reset_instructions delivers to user email" do
    user = users(:admin)
    mail = PasswordResetMailer.reset_instructions(user)
    assert_equal [ user.email_address ], mail.to
  end

  test "reset_instructions has correct subject" do
    user = users(:admin)
    mail = PasswordResetMailer.reset_instructions(user)
    assert_equal "Redefinição de senha — NAILA", mail.subject
  end

  test "reset_instructions sends from noreply address" do
    user = users(:admin)
    mail = PasswordResetMailer.reset_instructions(user)
    assert_match "noreply@naila.curitiba.pr.gov.br", mail.from.first
  end

  test "reset_instructions body contains reset URL path" do
    user = users(:admin)
    mail = PasswordResetMailer.reset_instructions(user)
    assert_match "reset-password", mail.body.encoded
  end

  test "reset_instructions body contains user name" do
    user = users(:admin)
    mail = PasswordResetMailer.reset_instructions(user)
    assert_match user.name, mail.body.encoded
  end
end
