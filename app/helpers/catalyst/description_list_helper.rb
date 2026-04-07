module Catalyst::DescriptionListHelper
  DL_CLASSES = "grid grid-cols-1 text-base/6 sm:grid-cols-[min(50%,--spacing(80))_auto] sm:text-sm/6".freeze
  DT_CLASSES = "col-start-1 border-t border-zinc-950/5 pt-3 text-zinc-500 first:border-none sm:border-t sm:border-zinc-950/5 sm:py-3 dark:border-white/5 dark:text-zinc-400 sm:dark:border-white/5".freeze
  DD_CLASSES = "pt-1 pb-3 text-zinc-950 sm:border-t sm:border-zinc-950/5 sm:py-3 sm:nth-2:border-none dark:text-white dark:sm:border-white/5".freeze

  def catalyst_dl(**opts, &block)
    css = [DL_CLASSES, opts.delete(:class)].compact.join(" ")
    tag.dl(class: css, **opts, &block)
  end

  def catalyst_dt(text = nil, **opts, &block)
    content = block ? capture(&block) : text
    css = [DT_CLASSES, opts.delete(:class)].compact.join(" ")
    tag.dt(content, class: css, **opts)
  end

  def catalyst_dd(text = nil, **opts, &block)
    content = block ? capture(&block) : text
    css = [DD_CLASSES, opts.delete(:class)].compact.join(" ")
    tag.dd(content, class: css, **opts)
  end
end
