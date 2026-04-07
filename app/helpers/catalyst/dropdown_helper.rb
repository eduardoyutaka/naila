module Catalyst::DropdownHelper
  MENU_CLASSES = [
    "isolate w-max rounded-xl p-1",
    "outline outline-transparent focus:outline-hidden",
    "overflow-y-auto",
    "bg-white/75 backdrop-blur-xl dark:bg-zinc-800/75",
    "shadow-lg ring-1 ring-zinc-950/10 dark:ring-white/10 dark:ring-inset",
  ].join(" ").freeze

  ITEM_CLASSES = [
    "group cursor-default rounded-lg px-3.5 py-2.5 focus:outline-hidden sm:px-3 sm:py-1.5",
    "text-left text-base/6 text-zinc-950 sm:text-sm/6 dark:text-white forced-colors:text-[CanvasText]",
    "focus:bg-blue-500 focus:text-white",
    "disabled:opacity-50",
    "w-full flex items-center gap-2",
  ].join(" ").freeze

  DIVIDER_CLASSES = "mx-3.5 my-1 h-px border-0 bg-zinc-950/5 sm:mx-3 dark:bg-white/10 forced-colors:bg-[CanvasText]".freeze

  HEADING_CLASSES = "px-3.5 pt-2 pb-1 text-sm/5 font-medium text-zinc-500 sm:px-3 sm:text-xs/5 dark:text-zinc-400".freeze

  # Wraps a dropdown trigger + menu.
  def catalyst_dropdown(**opts, &block)
    tag.div(data: { controller: "shared--dropdown" }, **opts, &block)
  end

  # The trigger button. Pass an `id` matching the menu's `popovertarget`.
  def catalyst_dropdown_button(text = nil, menu_id:, **opts, &block)
    content = block ? capture(&block) : text
    opts[:popovertarget] = menu_id
    opts[:data] = (opts[:data] || {}).merge(shared__dropdown_target: "button")
    catalyst_button(variant: :plain, **opts) { content }
  end

  # The popover menu panel.
  def catalyst_dropdown_menu(id:, anchor: "bottom", **opts, &block)
    css = [MENU_CLASSES, opts.delete(:class)].compact.join(" ")
    tag.div(
      id: id,
      popover: "",
      role: "menu",
      class: css,
      data: { shared__dropdown_target: "menu", action: "keydown->shared--dropdown#keydown" },
      **opts,
      &block
    )
  end

  # A single menu item. Renders <a> if href given, <button> otherwise.
  def catalyst_dropdown_item(text = nil, href: nil, **opts, &block)
    content = block ? capture(&block) : text
    css = [ITEM_CLASSES, opts.delete(:class)].compact.join(" ")
    if href
      tag.a(content, href: href, role: "menuitem", class: css, **opts)
    else
      tag.button(content, type: "button", role: "menuitem", class: css, **opts)
    end
  end

  def catalyst_dropdown_divider(**opts)
    tag.hr(role: "presentation", class: [DIVIDER_CLASSES, opts.delete(:class)].compact.join(" "), **opts)
  end

  def catalyst_dropdown_heading(text = nil, **opts, &block)
    content = block ? capture(&block) : text
    css = [HEADING_CLASSES, opts.delete(:class)].compact.join(" ")
    tag.div(content, class: css, **opts)
  end
end
