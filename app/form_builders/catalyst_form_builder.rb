class CatalystFormBuilder < ActionView::Helpers::FormBuilder
  INPUT_WRAPPER = [
    "relative block w-full",
    "before:absolute before:inset-px before:rounded-[calc(var(--radius-lg)-1px)] before:bg-white before:shadow-sm",
    "dark:before:hidden",
    "after:pointer-events-none after:absolute after:inset-0 after:rounded-lg after:ring-transparent after:ring-inset sm:focus-within:after:ring-2 sm:focus-within:after:ring-blue-500",
    "has-[:disabled]:opacity-50 has-[:disabled]:before:bg-zinc-950/5 has-[:disabled]:before:shadow-none",
  ].join(" ").freeze

  INPUT_CLASSES = [
    "relative block w-full appearance-none rounded-lg px-[calc(--spacing(3.5)-1px)] py-[calc(--spacing(2.5)-1px)] sm:px-[calc(--spacing(3)-1px)] sm:py-[calc(--spacing(1.5)-1px)]",
    "text-base/6 text-zinc-950 placeholder:text-zinc-500 sm:text-sm/6 dark:text-white",
    "border border-zinc-950/10 hover:border-zinc-950/20 dark:border-white/10 dark:hover:border-white/20",
    "bg-transparent dark:bg-white/5",
    "focus:outline-hidden",
    "disabled:border-zinc-950/20 dark:disabled:border-white/15 dark:disabled:bg-white/2.5 dark:hover:disabled:border-white/15",
  ].join(" ").freeze

  TEXTAREA_CLASSES = [
    "relative block h-full w-full appearance-none rounded-lg px-[calc(--spacing(3.5)-1px)] py-[calc(--spacing(2.5)-1px)] sm:px-[calc(--spacing(3)-1px)] sm:py-[calc(--spacing(1.5)-1px)]",
    "text-base/6 text-zinc-950 placeholder:text-zinc-500 sm:text-sm/6 dark:text-white",
    "border border-zinc-950/10 hover:border-zinc-950/20 dark:border-white/10 dark:hover:border-white/20",
    "bg-transparent dark:bg-white/5",
    "focus:outline-hidden",
    "disabled:border-zinc-950/20 dark:disabled:border-white/15 dark:disabled:bg-white/2.5 dark:hover:disabled:border-white/15",
    "resize-y",
  ].join(" ").freeze

  SELECT_WRAPPER = [
    "group relative block w-full",
    "before:absolute before:inset-px before:rounded-[calc(var(--radius-lg)-1px)] before:bg-white before:shadow-sm",
    "dark:before:hidden",
    "after:pointer-events-none after:absolute after:inset-0 after:rounded-lg after:ring-transparent after:ring-inset has-[:focus]:after:ring-2 has-[:focus]:after:ring-blue-500",
    "has-[:disabled]:opacity-50 has-[:disabled]:before:bg-zinc-950/5 has-[:disabled]:before:shadow-none",
  ].join(" ").freeze

  SELECT_CLASSES = [
    "relative block w-full appearance-none rounded-lg py-[calc(--spacing(2.5)-1px)] sm:py-[calc(--spacing(1.5)-1px)]",
    "pr-[calc(--spacing(10)-1px)] pl-[calc(--spacing(3.5)-1px)] sm:pr-[calc(--spacing(9)-1px)] sm:pl-[calc(--spacing(3)-1px)]",
    "text-base/6 text-zinc-950 placeholder:text-zinc-500 sm:text-sm/6 dark:text-white dark:*:text-white",
    "border border-zinc-950/10 hover:border-zinc-950/20 dark:border-white/10 dark:hover:border-white/20",
    "bg-transparent dark:bg-white/5 dark:*:bg-zinc-800",
    "focus:outline-hidden",
    "disabled:border-zinc-950/20 disabled:opacity-100 dark:disabled:border-white/15 dark:disabled:bg-white/2.5 dark:hover:disabled:border-white/15",
  ].join(" ").freeze

  LABEL_CLASSES = "text-base/6 text-zinc-950 select-none sm:text-sm/6 dark:text-white font-medium".freeze

  DESCRIPTION_CLASSES = "text-base/6 text-zinc-500 sm:text-sm/6 dark:text-zinc-400".freeze

  ERROR_CLASSES = "text-base/6 text-red-600 sm:text-sm/6 dark:text-red-500".freeze

  FIELD_CLASSES = [
    "[&>[data-slot=label]+[data-slot=control]]:mt-3",
    "[&>[data-slot=label]+[data-slot=description]]:mt-1",
    "[&>[data-slot=description]+[data-slot=control]]:mt-3",
    "[&>[data-slot=control]+[data-slot=description]]:mt-3",
    "[&>[data-slot=control]+[data-slot=error]]:mt-3",
    "*:data-[slot=label]:font-medium",
  ].join(" ").freeze

  CHEVRON_SVG = '<span class="pointer-events-none absolute inset-y-0 right-0 flex items-center pr-2"><svg class="size-5 stroke-zinc-500 group-has-[:disabled]:stroke-zinc-600 sm:size-4 dark:stroke-zinc-400 forced-colors:stroke-[CanvasText]" viewBox="0 0 16 16" aria-hidden="true" fill="none"><path d="M5.75 10.75L8 13L10.25 10.75" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" /><path d="M10.25 5.25L8 3L5.75 5.25" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" /></svg></span>'.html_safe.freeze

  # -- Label --
  def label(method, text = nil, **opts, &block)
    opts[:class] = merge_classes(LABEL_CLASSES, opts[:class])
    opts[:data] = (opts[:data] || {}).merge(slot: "label")
    super
  end

  # -- Text fields --
  %i[text_field email_field password_field number_field url_field search_field telephone_field date_field datetime_local_field].each do |method_name|
    define_method(method_name) do |method, **opts|
      opts[:class] = merge_classes(INPUT_CLASSES, opts[:class])
      @template.tag.span(class: INPUT_WRAPPER, data: { slot: "control" }) { super(method, **opts) }
    end
  end

  # -- Textarea --
  def text_area(method, **opts)
    resizable = opts.delete(:resizable) != false
    base = resizable ? TEXTAREA_CLASSES : TEXTAREA_CLASSES.sub("resize-y", "resize-none")
    opts[:class] = merge_classes(base, opts[:class])
    @template.tag.span(class: INPUT_WRAPPER, data: { slot: "control" }) { super(method, **opts) }
  end

  # -- Select --
  def select(method, choices = nil, options = {}, **html_opts, &block)
    html_opts[:class] = merge_classes(SELECT_CLASSES, html_opts[:class])
    @template.tag.span(class: SELECT_WRAPPER, data: { slot: "control" }) do
      @template.safe_join([super(method, choices, options, **html_opts, &block), CHEVRON_SVG])
    end
  end

  def collection_select(method, collection, value_method, text_method, options = {}, **html_opts)
    html_opts[:class] = merge_classes(SELECT_CLASSES, html_opts[:class])
    @template.tag.span(class: SELECT_WRAPPER, data: { slot: "control" }) do
      @template.safe_join([super, CHEVRON_SVG])
    end
  end

  # -- Checkbox --
  def check_box(method, options = {}, checked_value = "1", unchecked_value = "0")
    options[:class] = merge_classes(
      "size-4 rounded-[0.3125rem] border border-zinc-950/15 bg-white shadow-sm checked:border-transparent checked:bg-zinc-900 focus:outline-2 focus:outline-offset-2 focus:outline-blue-500 dark:bg-white/5 dark:border-white/15 dark:checked:bg-zinc-600",
      options[:class]
    )
    super
  end

  # -- Field wrapper (label + control spacing) --
  def field(**opts, &block)
    css = merge_classes(FIELD_CLASSES, opts.delete(:class))
    @template.tag.div(class: css, **opts, &block)
  end

  # -- Field group (vertical stack of fields) --
  def field_group(**opts, &block)
    css = merge_classes("space-y-8", opts.delete(:class))
    @template.tag.div(class: css, data: { slot: "control" }, **opts, &block)
  end

  # -- Description text --
  def description(text = nil, **opts, &block)
    content = block ? @template.capture(&block) : text
    css = merge_classes(DESCRIPTION_CLASSES, opts.delete(:class))
    @template.tag.p(content, class: css, data: { slot: "description" }, **opts)
  end

  # -- Error message for a field --
  def error_message(method, **opts)
    return unless object&.errors&.[](method)&.any?

    messages = object.errors[method].join(", ")
    css = merge_classes(ERROR_CLASSES, opts.delete(:class))
    @template.tag.p(messages, class: css, data: { slot: "error" }, **opts)
  end

  # -- Submit button with Catalyst solid button styling --
  def submit(value = nil, **opts)
    opts[:class] = merge_classes(
      Catalyst::ButtonHelper::BUTTON_BASE,
      Catalyst::ButtonHelper::BUTTON_SOLID,
      Catalyst::ButtonHelper::BUTTON_COLORS["sky"],
      "cursor-pointer",
      opts[:class]
    )
    super
  end

  # -- Error summary --
  def error_summary(**opts)
    return unless object&.errors&.any?

    @template.tag.div(class: "rounded-lg border border-red-500/30 bg-red-500/10 px-4 py-3") do
      @template.safe_join([
        @template.tag.p("#{object.errors.count} erro(s) impediu(iram) o salvamento:", class: "text-sm font-medium text-red-400"),
        @template.tag.ul(class: "mt-2 list-disc pl-5 text-sm text-red-400/80") {
          @template.safe_join(object.errors.full_messages.map { |msg| @template.tag.li(msg) })
        },
      ])
    end
  end

  private

  def merge_classes(*parts)
    parts.compact.join(" ").presence
  end
end
