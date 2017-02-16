# frozen_string_literal: true
class SlackWebhookNotificationRenderer
  def self.render(deploy, subject)
    controller = ActionController::Base.new
    view = ActionView::Base.new(File.expand_path("../../views/samson_slack_webhooks", __FILE__), {}, controller)
    show_prs = deploy.pending? || deploy.running?
    show_no_pr_warning = ! ENV.member? "SLACK_DISABLE_PR_WARNING"
    status_emoji = if deploy.pending?
      ':stopwatch:'
    elsif deploy.running?
      ':truck::dash:'
    elsif deploy.errored?
      ':x:'
    elsif deploy.failed?
      ':x:'
    elsif deploy.succeeded?
      ':white_check_mark:'
    else
      ''
    end
    locals = {
      deploy: deploy,
      status_emoji: status_emoji,
      changeset: deploy.changeset,
      subject: subject,
      show_prs: show_prs
      show_no_pr_warning: show_no_pr_warning
    }
    view.render(template: 'notification', locals: locals).chomp
  end
end
