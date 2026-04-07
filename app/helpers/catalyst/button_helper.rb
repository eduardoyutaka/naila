module Catalyst::ButtonHelper
  # Renders a <button> with Catalyst styling.
  #   catalyst_button("Save", variant: :solid, color: "sky")
  #   catalyst_button(variant: :outline) { "Cancel" }
  def catalyst_button(text = nil, variant: :solid, color: "dark/zinc", **opts, &block)
    content = block ? capture(&block) : text
    css = button_classes(variant, color, opts.delete(:class))
    opts[:type] ||= "button"
    tag.button(class: css, **opts) { touch_target(content) }
  end

  # Renders an <a> styled as a Catalyst button.
  #   catalyst_button_link("New User", href: new_admin_user_path, color: "sky")
  def catalyst_button_link(text = nil, href:, variant: :solid, color: "dark/zinc", **opts, &block)
    content = block ? capture(&block) : text
    css = button_classes(variant, color, opts.delete(:class))
    tag.a(href: href, class: css, **opts) { touch_target(content) }
  end

  private

  BUTTON_BASE = [
    # Base
    "relative isolate inline-flex items-baseline justify-center gap-x-2 rounded-lg border text-base/6 font-semibold",
    # Sizing
    "px-[calc(--spacing(3.5)-1px)] py-[calc(--spacing(2.5)-1px)] sm:px-[calc(--spacing(3)-1px)] sm:py-[calc(--spacing(1.5)-1px)] sm:text-sm/6",
    # Focus
    "focus:outline-hidden focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-500",
    # Disabled
    "disabled:opacity-50",
    # Icon
    "*:data-[slot=icon]:-mx-0.5 *:data-[slot=icon]:my-0.5 *:data-[slot=icon]:size-5 *:data-[slot=icon]:shrink-0 *:data-[slot=icon]:self-center *:data-[slot=icon]:text-(--btn-icon) sm:*:data-[slot=icon]:my-1 sm:*:data-[slot=icon]:size-4 forced-colors:[--btn-icon:ButtonText] forced-colors:hover:[--btn-icon:ButtonText]",
  ].join(" ").freeze

  BUTTON_SOLID = [
    # Optical border
    "border-transparent bg-(--btn-border)",
    "dark:bg-(--btn-bg)",
    # Foreground layer
    "before:absolute before:inset-0 before:-z-10 before:rounded-[calc(var(--radius-lg)-1px)] before:bg-(--btn-bg)",
    "before:shadow-sm",
    "dark:before:hidden",
    # Dark border
    "dark:border-white/5",
    # Shim/overlay
    "after:absolute after:inset-0 after:-z-10 after:rounded-[calc(var(--radius-lg)-1px)]",
    "after:shadow-[inset_0_1px_--theme(--color-white/15%)]",
    # Hover
    "active:after:bg-(--btn-hover-overlay) hover:after:bg-(--btn-hover-overlay)",
    # Dark after
    "dark:after:-inset-px dark:after:rounded-lg",
    # Disabled
    "disabled:before:shadow-none disabled:after:shadow-none",
  ].join(" ").freeze

  BUTTON_OUTLINE = [
    "border-zinc-950/10 text-zinc-950 active:bg-zinc-950/2.5 hover:bg-zinc-950/2.5",
    "dark:border-white/15 dark:text-white dark:[--btn-bg:transparent] dark:active:bg-white/5 dark:hover:bg-white/5",
    "[--btn-icon:var(--color-zinc-500)] active:[--btn-icon:var(--color-zinc-700)] hover:[--btn-icon:var(--color-zinc-700)] dark:active:[--btn-icon:var(--color-zinc-400)] dark:hover:[--btn-icon:var(--color-zinc-400)]",
  ].join(" ").freeze

  BUTTON_PLAIN = [
    "border-transparent text-zinc-950 active:bg-zinc-950/5 hover:bg-zinc-950/5",
    "dark:text-white dark:active:bg-white/10 dark:hover:bg-white/10",
    "[--btn-icon:var(--color-zinc-500)] active:[--btn-icon:var(--color-zinc-700)] hover:[--btn-icon:var(--color-zinc-700)] dark:[--btn-icon:var(--color-zinc-500)] dark:active:[--btn-icon:var(--color-zinc-400)] dark:hover:[--btn-icon:var(--color-zinc-400)]",
  ].join(" ").freeze

  BUTTON_COLORS = {
    "dark/zinc" => "text-white [--btn-bg:var(--color-zinc-900)] [--btn-border:var(--color-zinc-950)]/90 [--btn-hover-overlay:var(--color-white)]/10 dark:text-white dark:[--btn-bg:var(--color-zinc-600)] dark:[--btn-hover-overlay:var(--color-white)]/5 [--btn-icon:var(--color-zinc-400)] active:[--btn-icon:var(--color-zinc-300)] hover:[--btn-icon:var(--color-zinc-300)]",
    "light" => "text-zinc-950 [--btn-bg:white] [--btn-border:var(--color-zinc-950)]/10 [--btn-hover-overlay:var(--color-zinc-950)]/2.5 active:[--btn-border:var(--color-zinc-950)]/15 hover:[--btn-border:var(--color-zinc-950)]/15 dark:text-white dark:[--btn-hover-overlay:var(--color-white)]/5 dark:[--btn-bg:var(--color-zinc-800)] [--btn-icon:var(--color-zinc-500)] active:[--btn-icon:var(--color-zinc-700)] hover:[--btn-icon:var(--color-zinc-700)] dark:[--btn-icon:var(--color-zinc-500)] dark:active:[--btn-icon:var(--color-zinc-400)] dark:hover:[--btn-icon:var(--color-zinc-400)]",
    "dark/white" => "text-white [--btn-bg:var(--color-zinc-900)] [--btn-border:var(--color-zinc-950)]/90 [--btn-hover-overlay:var(--color-white)]/10 dark:text-zinc-950 dark:[--btn-bg:white] dark:[--btn-hover-overlay:var(--color-zinc-950)]/5 [--btn-icon:var(--color-zinc-400)] active:[--btn-icon:var(--color-zinc-300)] hover:[--btn-icon:var(--color-zinc-300)] dark:[--btn-icon:var(--color-zinc-500)] dark:active:[--btn-icon:var(--color-zinc-400)] dark:hover:[--btn-icon:var(--color-zinc-400)]",
    "dark" => "text-white [--btn-bg:var(--color-zinc-900)] [--btn-border:var(--color-zinc-950)]/90 [--btn-hover-overlay:var(--color-white)]/10 dark:[--btn-hover-overlay:var(--color-white)]/5 dark:[--btn-bg:var(--color-zinc-800)] [--btn-icon:var(--color-zinc-400)] active:[--btn-icon:var(--color-zinc-300)] hover:[--btn-icon:var(--color-zinc-300)]",
    "white" => "text-zinc-950 [--btn-bg:white] [--btn-border:var(--color-zinc-950)]/10 [--btn-hover-overlay:var(--color-zinc-950)]/2.5 active:[--btn-border:var(--color-zinc-950)]/15 hover:[--btn-border:var(--color-zinc-950)]/15 dark:[--btn-hover-overlay:var(--color-zinc-950)]/5 [--btn-icon:var(--color-zinc-400)] active:[--btn-icon:var(--color-zinc-500)] hover:[--btn-icon:var(--color-zinc-500)]",
    "zinc" => "text-white [--btn-hover-overlay:var(--color-white)]/10 [--btn-bg:var(--color-zinc-600)] [--btn-border:var(--color-zinc-700)]/90 dark:[--btn-hover-overlay:var(--color-white)]/5 [--btn-icon:var(--color-zinc-400)] active:[--btn-icon:var(--color-zinc-300)] hover:[--btn-icon:var(--color-zinc-300)]",
    "indigo" => "text-white [--btn-hover-overlay:var(--color-white)]/10 [--btn-bg:var(--color-indigo-500)] [--btn-border:var(--color-indigo-600)]/90 [--btn-icon:var(--color-indigo-300)] active:[--btn-icon:var(--color-indigo-200)] hover:[--btn-icon:var(--color-indigo-200)]",
    "cyan" => "text-cyan-950 [--btn-bg:var(--color-cyan-300)] [--btn-border:var(--color-cyan-400)]/80 [--btn-hover-overlay:var(--color-white)]/25 [--btn-icon:var(--color-cyan-500)]",
    "red" => "text-white [--btn-hover-overlay:var(--color-white)]/10 [--btn-bg:var(--color-red-600)] [--btn-border:var(--color-red-700)]/90 [--btn-icon:var(--color-red-300)] active:[--btn-icon:var(--color-red-200)] hover:[--btn-icon:var(--color-red-200)]",
    "orange" => "text-white [--btn-hover-overlay:var(--color-white)]/10 [--btn-bg:var(--color-orange-500)] [--btn-border:var(--color-orange-600)]/90 [--btn-icon:var(--color-orange-300)] active:[--btn-icon:var(--color-orange-200)] hover:[--btn-icon:var(--color-orange-200)]",
    "amber" => "text-amber-950 [--btn-hover-overlay:var(--color-white)]/25 [--btn-bg:var(--color-amber-400)] [--btn-border:var(--color-amber-500)]/80 [--btn-icon:var(--color-amber-600)]",
    "yellow" => "text-yellow-950 [--btn-hover-overlay:var(--color-white)]/25 [--btn-bg:var(--color-yellow-300)] [--btn-border:var(--color-yellow-400)]/80 [--btn-icon:var(--color-yellow-600)] active:[--btn-icon:var(--color-yellow-700)] hover:[--btn-icon:var(--color-yellow-700)]",
    "lime" => "text-lime-950 [--btn-hover-overlay:var(--color-white)]/25 [--btn-bg:var(--color-lime-300)] [--btn-border:var(--color-lime-400)]/80 [--btn-icon:var(--color-lime-600)] active:[--btn-icon:var(--color-lime-700)] hover:[--btn-icon:var(--color-lime-700)]",
    "green" => "text-white [--btn-hover-overlay:var(--color-white)]/10 [--btn-bg:var(--color-green-600)] [--btn-border:var(--color-green-700)]/90 [--btn-icon:var(--color-white)]/60 active:[--btn-icon:var(--color-white)]/80 hover:[--btn-icon:var(--color-white)]/80",
    "emerald" => "text-white [--btn-hover-overlay:var(--color-white)]/10 [--btn-bg:var(--color-emerald-600)] [--btn-border:var(--color-emerald-700)]/90 [--btn-icon:var(--color-white)]/60 active:[--btn-icon:var(--color-white)]/80 hover:[--btn-icon:var(--color-white)]/80",
    "teal" => "text-white [--btn-hover-overlay:var(--color-white)]/10 [--btn-bg:var(--color-teal-600)] [--btn-border:var(--color-teal-700)]/90 [--btn-icon:var(--color-white)]/60 active:[--btn-icon:var(--color-white)]/80 hover:[--btn-icon:var(--color-white)]/80",
    "sky" => "text-white [--btn-hover-overlay:var(--color-white)]/10 [--btn-bg:var(--color-sky-500)] [--btn-border:var(--color-sky-600)]/80 [--btn-icon:var(--color-white)]/60 active:[--btn-icon:var(--color-white)]/80 hover:[--btn-icon:var(--color-white)]/80",
    "blue" => "text-white [--btn-hover-overlay:var(--color-white)]/10 [--btn-bg:var(--color-blue-600)] [--btn-border:var(--color-blue-700)]/90 [--btn-icon:var(--color-blue-400)] active:[--btn-icon:var(--color-blue-300)] hover:[--btn-icon:var(--color-blue-300)]",
    "violet" => "text-white [--btn-hover-overlay:var(--color-white)]/10 [--btn-bg:var(--color-violet-500)] [--btn-border:var(--color-violet-600)]/90 [--btn-icon:var(--color-violet-300)] active:[--btn-icon:var(--color-violet-200)] hover:[--btn-icon:var(--color-violet-200)]",
    "purple" => "text-white [--btn-hover-overlay:var(--color-white)]/10 [--btn-bg:var(--color-purple-500)] [--btn-border:var(--color-purple-600)]/90 [--btn-icon:var(--color-purple-300)] active:[--btn-icon:var(--color-purple-200)] hover:[--btn-icon:var(--color-purple-200)]",
    "fuchsia" => "text-white [--btn-hover-overlay:var(--color-white)]/10 [--btn-bg:var(--color-fuchsia-500)] [--btn-border:var(--color-fuchsia-600)]/90 [--btn-icon:var(--color-fuchsia-300)] active:[--btn-icon:var(--color-fuchsia-200)] hover:[--btn-icon:var(--color-fuchsia-200)]",
    "pink" => "text-white [--btn-hover-overlay:var(--color-white)]/10 [--btn-bg:var(--color-pink-500)] [--btn-border:var(--color-pink-600)]/90 [--btn-icon:var(--color-pink-300)] active:[--btn-icon:var(--color-pink-200)] hover:[--btn-icon:var(--color-pink-200)]",
    "rose" => "text-white [--btn-hover-overlay:var(--color-white)]/10 [--btn-bg:var(--color-rose-500)] [--btn-border:var(--color-rose-600)]/90 [--btn-icon:var(--color-rose-300)] active:[--btn-icon:var(--color-rose-200)] hover:[--btn-icon:var(--color-rose-200)]",
  }.freeze

  def button_classes(variant, color, extra_class)
    variant_css = case variant.to_sym
    when :outline then BUTTON_OUTLINE
    when :plain   then BUTTON_PLAIN
    else "#{BUTTON_SOLID} #{BUTTON_COLORS.fetch(color.to_s, BUTTON_COLORS["dark/zinc"])}"
    end
    [BUTTON_BASE, variant_css, extra_class].compact.join(" ")
  end

  def touch_target(content)
    safe_join([
      tag.span(aria: { hidden: true }, class: "absolute top-1/2 left-1/2 size-[max(100%,2.75rem)] -translate-x-1/2 -translate-y-1/2 pointer-fine:hidden"),
      content,
    ])
  end
end
