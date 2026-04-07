module Catalyst::AvatarHelper
  AVATAR_BASE = "inline-grid shrink-0 align-middle [--avatar-radius:20%] *:col-start-1 *:row-start-1 outline -outline-offset-1 outline-black/10 dark:outline-white/10".freeze

  # Renders a Catalyst avatar.
  #   catalyst_avatar(initials: "EN", class: "size-8")
  #   catalyst_avatar(src: user.avatar_url, alt: user.name, class: "size-10")
  def catalyst_avatar(src: nil, initials: nil, alt: "", square: false, **opts)
    radius = square ? "rounded-(--avatar-radius) *:rounded-(--avatar-radius)" : "rounded-full *:rounded-full"
    css = [AVATAR_BASE, radius, opts.delete(:class)].compact.join(" ")
    tag.span(class: css, data: { slot: "avatar" }, **opts) do
      parts = []
      if initials
        parts << tag.svg(
          class: "size-full fill-current p-[5%] text-[48px] font-medium uppercase select-none",
          viewBox: "0 0 100 100",
          aria: alt.blank? ? { hidden: true } : {}
        ) {
          safe_join([
            alt.present? ? tag.title(alt) : nil,
            tag.text(initials, x: "50%", y: "50%", "alignment-baseline": "middle", "dominant-baseline": "middle", "text-anchor": "middle", dy: ".125em"),
          ].compact)
        }
      end
      parts << tag.img(class: "size-full", src: src, alt: alt) if src
      safe_join(parts)
    end
  end
end
