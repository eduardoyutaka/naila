module Catalyst::TypographyHelper
  HEADING_CLASSES = "text-2xl/8 font-semibold text-zinc-950 sm:text-xl/8 dark:text-white".freeze
  SUBHEADING_CLASSES = "text-base/7 font-semibold text-zinc-950 sm:text-sm/6 dark:text-white".freeze
  TEXT_CLASSES = "text-base/6 text-zinc-500 sm:text-sm/6 dark:text-zinc-400".freeze
  STRONG_CLASSES = "font-medium text-zinc-950 dark:text-white".freeze
  CODE_CLASSES = "rounded-sm border border-zinc-950/10 bg-zinc-950/2.5 px-0.5 text-sm font-medium text-zinc-950 sm:text-[0.8125rem] dark:border-white/20 dark:bg-white/5 dark:text-white".freeze
  TEXT_LINK_CLASSES = "text-zinc-950 underline decoration-zinc-950/50 hover:decoration-zinc-950 dark:text-white dark:decoration-white/50 dark:hover:decoration-white".freeze

  def catalyst_heading(text = nil, level: 1, **opts, &block)
    content = block ? capture(&block) : text
    css = [HEADING_CLASSES, opts.delete(:class)].compact.join(" ")
    content_tag(:"h#{level}", content, class: css, **opts)
  end

  def catalyst_subheading(text = nil, level: 2, **opts, &block)
    content = block ? capture(&block) : text
    css = [SUBHEADING_CLASSES, opts.delete(:class)].compact.join(" ")
    content_tag(:"h#{level}", content, class: css, **opts)
  end

  def catalyst_text(text = nil, **opts, &block)
    content = block ? capture(&block) : text
    css = [TEXT_CLASSES, opts.delete(:class)].compact.join(" ")
    tag.p(content, class: css, data: { slot: "text" }, **opts)
  end

  def catalyst_strong(text = nil, **opts, &block)
    content = block ? capture(&block) : text
    css = [STRONG_CLASSES, opts.delete(:class)].compact.join(" ")
    tag.strong(content, class: css, **opts)
  end

  def catalyst_code(text = nil, **opts, &block)
    content = block ? capture(&block) : text
    css = [CODE_CLASSES, opts.delete(:class)].compact.join(" ")
    tag.code(content, class: css, **opts)
  end

  def catalyst_text_link(text = nil, href:, **opts, &block)
    content = block ? capture(&block) : text
    css = [TEXT_LINK_CLASSES, opts.delete(:class)].compact.join(" ")
    tag.a(content, href: href, class: css, **opts)
  end
end
