module Catalyst::DialogHelper
  DIALOG_SIZES = {
    "xs" => "sm:max-w-xs", "sm" => "sm:max-w-sm", "md" => "sm:max-w-md",
    "lg" => "sm:max-w-lg", "xl" => "sm:max-w-xl", "2xl" => "sm:max-w-2xl",
    "3xl" => "sm:max-w-3xl", "4xl" => "sm:max-w-4xl", "5xl" => "sm:max-w-5xl",
  }.freeze

  DIALOG_PANEL = "w-full min-w-0 rounded-t-3xl bg-white p-8 shadow-lg ring-1 ring-zinc-950/10 sm:mb-auto sm:rounded-2xl dark:bg-zinc-900 dark:ring-white/10 forced-colors:outline".freeze
  DIALOG_BACKDROP = "fixed inset-0 bg-zinc-950/25 dark:bg-zinc-950/50".freeze
  DIALOG_TITLE = "text-lg/6 font-semibold text-balance text-zinc-950 sm:text-base/6 dark:text-white".freeze
  DIALOG_BODY = "mt-6".freeze
  DIALOG_ACTIONS = "mt-8 flex flex-col-reverse items-center justify-end gap-3 *:w-full sm:flex-row sm:*:w-auto".freeze

  # Renders a <dialog> with Catalyst styling.
  #   catalyst_dialog(size: "lg") do
  #     catalyst_dialog_title("Confirm")
  #     ...
  #   end
  def catalyst_dialog(size: "lg", **opts, &block)
    css = [DIALOG_PANEL, DIALOG_SIZES.fetch(size.to_s, DIALOG_SIZES["lg"]), opts.delete(:class)].compact.join(" ")
    tag.dialog(
      class: "backdrop:#{DIALOG_BACKDROP.gsub(' ', ' backdrop:')} #{css}",
      data: { shared__dialog_target: "dialog", action: "click->shared--dialog#backdropClose" },
      **opts,
      &block
    )
  end

  def catalyst_dialog_title(text = nil, **opts, &block)
    content = block ? capture(&block) : text
    css = [DIALOG_TITLE, opts.delete(:class)].compact.join(" ")
    tag.h2(content, class: css, **opts)
  end

  def catalyst_dialog_description(text = nil, **opts, &block)
    content = block ? capture(&block) : text
    css = ["mt-2 text-pretty text-base/6 text-zinc-500 sm:text-sm/6 dark:text-zinc-400", opts.delete(:class)].compact.join(" ")
    tag.p(content, class: css, **opts)
  end

  def catalyst_dialog_body(**opts, &block)
    css = [DIALOG_BODY, opts.delete(:class)].compact.join(" ")
    tag.div(class: css, **opts, &block)
  end

  def catalyst_dialog_actions(**opts, &block)
    css = [DIALOG_ACTIONS, opts.delete(:class)].compact.join(" ")
    tag.div(class: css, **opts, &block)
  end

  # Alert variant (centered text on mobile, smaller default)
  def catalyst_alert(size: "md", **opts, &block)
    catalyst_dialog(size: size, **opts, &block)
  end

  def catalyst_alert_title(text = nil, **opts, &block)
    content = block ? capture(&block) : text
    css = ["text-center text-base/6 font-semibold text-balance text-zinc-950 sm:text-left sm:text-sm/6 sm:text-wrap dark:text-white", opts.delete(:class)].compact.join(" ")
    tag.h2(content, class: css, **opts)
  end

  def catalyst_alert_description(text = nil, **opts, &block)
    content = block ? capture(&block) : text
    css = ["mt-2 text-center text-pretty text-base/6 text-zinc-500 sm:text-left sm:text-sm/6 dark:text-zinc-400", opts.delete(:class)].compact.join(" ")
    tag.p(content, class: css, **opts)
  end

  def catalyst_alert_body(**opts, &block)
    css = ["mt-4", opts.delete(:class)].compact.join(" ")
    tag.div(class: css, **opts, &block)
  end

  def catalyst_alert_actions(**opts, &block)
    css = ["mt-6 flex flex-col-reverse items-center justify-end gap-3 *:w-full sm:mt-4 sm:flex-row sm:*:w-auto", opts.delete(:class)].compact.join(" ")
    tag.div(class: css, **opts, &block)
  end
end
