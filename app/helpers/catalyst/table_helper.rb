module Catalyst::TableHelper
  # Renders a Catalyst-styled table with optional bleed, dense, grid, striped.
  #
  #   <%= catalyst_table(dense: true, striped: true) do %>
  #     <%= catalyst_table_head do %>
  #       <tr><%= catalyst_th("Name") %><%= catalyst_th("Email") %></tr>
  #     <% end %>
  #     <%= catalyst_table_body do %>
  #       <% @users.each do |user| %>
  #         <%= catalyst_table_row do %>
  #           <%= catalyst_td(user.name) %>
  #           <%= catalyst_td(user.email) %>
  #         <% end %>
  #       <% end %>
  #     <% end %>
  #   <% end %>
  def catalyst_table(bleed: false, dense: false, grid: false, striped: false, **opts, &block)
    prev = @_catalyst_table_opts
    @_catalyst_table_opts = { bleed: bleed, dense: dense, grid: grid, striped: striped }
    css = ["-mx-(--gutter) overflow-x-auto whitespace-nowrap", opts.delete(:class)].compact.join(" ")
    inner_css = ["inline-block min-w-full align-middle", bleed ? nil : "sm:px-(--gutter)"].compact.join(" ")

    html = tag.div(class: "flow-root") do
      tag.div(class: css, **opts) do
        tag.div(class: inner_css) do
          tag.table(class: "min-w-full text-left text-sm/6 text-zinc-950 dark:text-white", &block)
        end
      end
    end
    @_catalyst_table_opts = prev
    html
  end

  def catalyst_table_head(**opts, &block)
    css = ["text-zinc-500 dark:text-zinc-400", opts.delete(:class)].compact.join(" ")
    tag.thead(class: css, **opts, &block)
  end

  def catalyst_table_body(**opts, &block)
    tag.tbody(**opts, &block)
  end

  def catalyst_table_row(href: nil, **opts, &block)
    t = @_catalyst_table_opts || {}
    classes = []
    if href
      classes << "has-[[data-row-link]:focus-visible]:outline-2 has-[[data-row-link]:focus-visible]:-outline-offset-2 has-[[data-row-link]:focus-visible]:outline-blue-500 dark:focus-within:bg-white/2.5"
    end
    classes << "even:bg-zinc-950/2.5 dark:even:bg-white/2.5" if t[:striped]
    classes << "hover:bg-zinc-950/5 dark:hover:bg-white/5" if href && t[:striped]
    classes << "hover:bg-zinc-950/2.5 dark:hover:bg-white/2.5" if href && !t[:striped]
    classes << opts.delete(:class) if opts[:class]

    tag.tr(class: classes.compact.join(" ").presence, **opts, &block)
  end

  def catalyst_th(text = nil, **opts, &block)
    content = block ? capture(&block) : text
    t = @_catalyst_table_opts || {}
    classes = [
      "border-b border-b-zinc-950/10 px-4 py-2 font-medium first:pl-(--gutter,--spacing(2)) last:pr-(--gutter,--spacing(2)) dark:border-b-white/10",
      t[:grid] ? "border-l border-l-zinc-950/5 first:border-l-0 dark:border-l-white/5" : nil,
      t[:bleed] ? nil : "sm:first:pl-1 sm:last:pr-1",
      opts.delete(:class),
    ].compact.join(" ")
    tag.th(content, class: classes, **opts)
  end

  def catalyst_td(text = nil, **opts, &block)
    content = block ? capture(&block) : text
    t = @_catalyst_table_opts || {}
    classes = [
      "relative px-4 first:pl-(--gutter,--spacing(2)) last:pr-(--gutter,--spacing(2))",
      t[:striped] ? nil : "border-b border-zinc-950/5 dark:border-white/5",
      t[:grid] ? "border-l border-l-zinc-950/5 first:border-l-0 dark:border-l-white/5" : nil,
      t[:dense] ? "py-2.5" : "py-4",
      t[:bleed] ? nil : "sm:first:pl-1 sm:last:pr-1",
      opts.delete(:class),
    ].compact.join(" ")
    tag.td(content, class: classes, **opts)
  end
end
