module Catalyst::NavbarHelper
  NAVBAR_CLASSES = "flex flex-1 items-center gap-4 py-2.5".freeze

  NAVBAR_SECTION_CLASSES = "flex items-center gap-3".freeze

  NAVBAR_ITEM_CLASSES = [
    "relative flex min-w-0 items-center gap-3 rounded-lg p-2 text-left text-base/6 font-medium text-zinc-950 sm:text-sm/5",
    "*:data-[slot=icon]:size-6 *:data-[slot=icon]:shrink-0 *:data-[slot=icon]:fill-zinc-500 sm:*:data-[slot=icon]:size-5",
    "hover:bg-zinc-950/5 hover:*:data-[slot=icon]:fill-zinc-950",
    "active:bg-zinc-950/5 active:*:data-[slot=icon]:fill-zinc-950",
    "dark:text-white dark:*:data-[slot=icon]:fill-zinc-400",
    "dark:hover:bg-white/5 dark:hover:*:data-[slot=icon]:fill-white",
    "dark:active:bg-white/5 dark:active:*:data-[slot=icon]:fill-white",
  ].join(" ").freeze

  NAVBAR_DIVIDER_CLASSES = "h-6 w-px bg-zinc-950/10 dark:bg-white/10".freeze

  def catalyst_navbar(**opts, &block)
    css = [NAVBAR_CLASSES, opts.delete(:class)].compact.join(" ")
    tag.nav(class: css, **opts, &block)
  end

  def catalyst_navbar_section(**opts, &block)
    css = [NAVBAR_SECTION_CLASSES, opts.delete(:class)].compact.join(" ")
    tag.div(class: css, **opts, &block)
  end

  def catalyst_navbar_item(text = nil, href: nil, current: false, **opts, &block)
    content = block ? capture(&block) : text
    css = [NAVBAR_ITEM_CLASSES, opts.delete(:class)].compact.join(" ")
    aria = current ? { current: "page" } : {}

    tag.span(class: "relative") do
      safe_join([
        current ? tag.span(class: "absolute inset-x-2 -bottom-2.5 h-0.5 rounded-full bg-zinc-950 dark:bg-white") : nil,
        href ? tag.a(content, href: href, class: css, aria: aria, **opts) : tag.button(content, type: "button", class: "cursor-default #{css}", aria: aria, **opts),
      ].compact)
    end
  end

  def catalyst_navbar_divider(**opts)
    css = [NAVBAR_DIVIDER_CLASSES, opts.delete(:class)].compact.join(" ")
    tag.div(aria: { hidden: true }, class: css, **opts)
  end

  def catalyst_navbar_spacer(**opts)
    css = ["-ml-4 flex-1", opts.delete(:class)].compact.join(" ")
    tag.div(aria: { hidden: true }, class: css, **opts)
  end

  def catalyst_navbar_label(text = nil, **opts, &block)
    content = block ? capture(&block) : text
    css = ["truncate", opts.delete(:class)].compact.join(" ")
    tag.span(content, class: css, **opts)
  end
end
