module Catalyst::SidebarHelper
  SIDEBAR_CLASSES = "flex h-full min-h-0 flex-col".freeze

  SIDEBAR_HEADER_CLASSES = "flex flex-col border-b border-zinc-950/5 p-4 dark:border-white/5 [&>[data-slot=section]+[data-slot=section]]:mt-2.5".freeze

  SIDEBAR_BODY_CLASSES = "flex flex-1 flex-col overflow-y-auto p-4 [&>[data-slot=section]+[data-slot=section]]:mt-8".freeze

  SIDEBAR_FOOTER_CLASSES = "flex flex-col border-t border-zinc-950/5 p-4 dark:border-white/5 [&>[data-slot=section]+[data-slot=section]]:mt-2.5".freeze

  SIDEBAR_SECTION_CLASSES = "flex flex-col gap-0.5".freeze

  SIDEBAR_ITEM_CLASSES = [
    "flex w-full items-center gap-3 rounded-lg px-2 py-2.5 text-left text-base/6 font-medium text-zinc-950 sm:py-2 sm:text-sm/5",
    "*:data-[slot=icon]:size-6 *:data-[slot=icon]:shrink-0 *:data-[slot=icon]:fill-zinc-500 sm:*:data-[slot=icon]:size-5",
    "hover:bg-zinc-950/5 hover:*:data-[slot=icon]:fill-zinc-950",
    "active:bg-zinc-950/5 active:*:data-[slot=icon]:fill-zinc-950",
    "aria-[current=page]:*:data-[slot=icon]:fill-zinc-950",
    "dark:text-white dark:*:data-[slot=icon]:fill-zinc-400",
    "dark:hover:bg-white/5 dark:hover:*:data-[slot=icon]:fill-white",
    "dark:active:bg-white/5 dark:active:*:data-[slot=icon]:fill-white",
    "dark:aria-[current=page]:*:data-[slot=icon]:fill-white",
  ].join(" ").freeze

  SIDEBAR_HEADING_CLASSES = "mb-1 px-2 text-xs/6 font-medium text-zinc-500 dark:text-zinc-400".freeze

  SIDEBAR_DIVIDER_CLASSES = "my-4 border-t border-zinc-950/5 lg:-mx-4 dark:border-white/5".freeze

  def catalyst_sidebar(**opts, &block)
    css = [SIDEBAR_CLASSES, opts.delete(:class)].compact.join(" ")
    tag.nav(class: css, **opts, &block)
  end

  def catalyst_sidebar_header(**opts, &block)
    css = [SIDEBAR_HEADER_CLASSES, opts.delete(:class)].compact.join(" ")
    tag.div(class: css, **opts, &block)
  end

  def catalyst_sidebar_body(**opts, &block)
    css = [SIDEBAR_BODY_CLASSES, opts.delete(:class)].compact.join(" ")
    tag.div(class: css, **opts, &block)
  end

  def catalyst_sidebar_footer(**opts, &block)
    css = [SIDEBAR_FOOTER_CLASSES, opts.delete(:class)].compact.join(" ")
    tag.div(class: css, **opts, &block)
  end

  def catalyst_sidebar_section(**opts, &block)
    css = [SIDEBAR_SECTION_CLASSES, opts.delete(:class)].compact.join(" ")
    tag.div(class: css, data: { slot: "section" }, **opts, &block)
  end

  # Renders a sidebar navigation item.
  #   catalyst_sidebar_item("Dashboard", href: admin_root_path, current: current_page?(admin_root_path))
  def catalyst_sidebar_item(text = nil, href:, current: false, **opts, &block)
    content = block ? capture(&block) : text
    css = [SIDEBAR_ITEM_CLASSES, opts.delete(:class)].compact.join(" ")
    aria = current ? { current: "page" } : {}

    tag.span(class: "relative") do
      safe_join([
        current ? tag.span(class: "absolute inset-y-2 -left-4 w-0.5 rounded-full bg-zinc-950 dark:bg-white") : nil,
        tag.a(href: href, class: css, aria: aria, **opts) { content },
      ].compact)
    end
  end

  def catalyst_sidebar_heading(text = nil, **opts, &block)
    content = block ? capture(&block) : text
    css = [SIDEBAR_HEADING_CLASSES, opts.delete(:class)].compact.join(" ")
    tag.h3(content, class: css, **opts)
  end

  def catalyst_sidebar_divider(**opts)
    css = [SIDEBAR_DIVIDER_CLASSES, opts.delete(:class)].compact.join(" ")
    tag.hr(class: css, **opts)
  end

  def catalyst_sidebar_spacer(**opts)
    css = ["mt-8 flex-1", opts.delete(:class)].compact.join(" ")
    tag.div(aria: { hidden: true }, class: css, **opts)
  end

  def catalyst_sidebar_label(text = nil, **opts, &block)
    content = block ? capture(&block) : text
    css = ["truncate", opts.delete(:class)].compact.join(" ")
    tag.span(content, class: css, **opts)
  end
end
