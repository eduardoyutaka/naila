module Catalyst::PaginationHelper
  # Renders Catalyst-styled pagination.
  #   catalyst_pagination(prev_href: "/page/1", next_href: "/page/3", pages: [1,2,3,4,5], current_page: 2, page_href: ->(p) { "/page/#{p}" })
  def catalyst_pagination(prev_href: nil, next_href: nil, pages: [], current_page: nil, page_href: nil, **opts)
    css = ["flex gap-x-2", opts.delete(:class)].compact.join(" ")

    tag.nav(aria: { label: "Navegação de páginas" }, class: css, **opts) do
      safe_join([
        # Previous
        tag.span(class: "grow basis-0") {
          if prev_href
            catalyst_button_link(href: prev_href, variant: :plain) do
              safe_join([
                tag.svg(class: "stroke-current", data: { slot: "icon" }, viewBox: "0 0 16 16", fill: "none", aria: { hidden: true }) {
                  tag.path(d: "M2.75 8H13.25M2.75 8L5.25 5.5M2.75 8L5.25 10.5", "stroke-width": "1.5", "stroke-linecap": "round", "stroke-linejoin": "round")
                },
                "Anterior",
              ])
            end
          else
            catalyst_button("Anterior", variant: :plain, disabled: true)
          end
        },
        # Page numbers
        tag.span(class: "hidden items-baseline gap-x-2 sm:flex") {
          safe_join(pages.map { |page|
            if page == :gap
              tag.span("&hellip;".html_safe, aria: { hidden: true }, class: "w-9 text-center text-sm/6 font-semibold text-zinc-950 select-none dark:text-white")
            else
              href = page_href&.call(page)
              is_current = page == current_page
              catalyst_button_link(page.to_s, href: href, variant: :plain, aria: is_current ? { current: "page" } : {}, class: "min-w-9 #{is_current ? 'before:absolute before:-inset-px before:rounded-lg before:bg-zinc-950/5 dark:before:bg-white/10' : ''}")
            end
          })
        },
        # Next
        tag.span(class: "flex grow basis-0 justify-end") {
          if next_href
            catalyst_button_link(href: next_href, variant: :plain) do
              safe_join([
                "Próximo",
                tag.svg(class: "stroke-current", data: { slot: "icon" }, viewBox: "0 0 16 16", fill: "none", aria: { hidden: true }) {
                  tag.path(d: "M13.25 8L2.75 8M13.25 8L10.75 10.5M13.25 8L10.75 5.5", "stroke-width": "1.5", "stroke-linecap": "round", "stroke-linejoin": "round")
                },
              ])
            end
          else
            catalyst_button("Próximo", variant: :plain, disabled: true)
          end
        },
      ])
    end
  end
end
