;; Home row mods with additional nav layer on space hold

(defsrc
  esc   1    2    3    4    5    6    7    8    9    0    -    =    grv  bspc
  tab   q    w    e    r    t    y    u    i    o    p    [    ]    \    del
  caps  a    s    d    f    g    h    j    k    l    ;    '    ret       pgup
  lsft  z    x    c    v    b    n    m    ,    .    /    rsft      ▲    pgdn
  lctl  lmet lalt           spc            ralt rmet rctl      ◀    ▼    ▶
)

(defvar
  tap-time 200
  hold-time 150

  left-hand-keys (
    q w e r t
    a s d f g
    z x c v b
  )
  right-hand-keys (
    y u i o p
    h j k l ;
    n m , . /
  )
)

;; Symbol aliases for the nav layer
(defalias
  ;; Parentheses
  op S-9
  cp S-0
  ;; Curly braces
  ob S-[
  cb S-]
  ;; Angle brackets
  lt S-,
  gt S-.
  
  ;; Space tap-hold for nav layer
  spc (tap-hold 150 200 spc (layer-while-held nav))
)

(deflayer base
  esc   1     2     3     4     5     6     7     8     9     0     -     =     grv   bspc
  tab   q     w     e     r     t     y     u     i     o     p     [     ]     \     del
  caps  @a    @s    @d    @f    g     h     @j    @k    @l    @;    '     ret         pgup
  lsft  z     x     c     v     b     n     m     ,     .     /     rsft        ▲     pgdn
  lctl  lmet  lalt              @spc              ralt  rmet  rctl        ◀     ▼     ▶
)

(deflayer nomods
  esc   1    2    3    4    5    6    7    8    9    0    -    =    grv  bspc
  tab   q    w    e    r    t    y    u    i    o    p    [    ]    \    del
  caps  a    s    d    f    g    h    j    k    l    ;    '    ret       pgup
  lsft  z    x    c    v    b    n    m    ,    .    /    rsft      ▲    pgdn
  lctl  lmet lalt           spc            ralt rmet rctl      ◀    ▼    ▶
)

;; Navigation and symbols layer activated by holding space
(deflayer nav
  _     _     _     _     _     _     _     _     [     ]     _     _     _     _     _
  _     -     @lt   @gt   =     grv   \     @ob   @op   @cp   @cb   _     _     _     _
  _     home  del  bspc  ret    end   ◀     ▼     ▲     ▶     _     _     _           _
  _     _     _     _     _     _     _     _     _     _     _     _           _     _
  _     _     _                 _                 _     _     _           _     _     _
)

(deffakekeys
  to-base (layer-switch base)
)

(defalias
  tap (multi
    (layer-switch nomods)
    (on-idle-fakekey to-base tap 20)
  )

  a (tap-hold-release-keys $tap-time $hold-time (multi a @tap) lmet $left-hand-keys)
  s (tap-hold-release-keys $tap-time $hold-time (multi s @tap) lalt $left-hand-keys)
  d (tap-hold-release-keys $tap-time $hold-time (multi d @tap) lsft $left-hand-keys)
  f (tap-hold-release-keys $tap-time $hold-time (multi f @tap) lctl $left-hand-keys)
  j (tap-hold-release-keys $tap-time $hold-time (multi j @tap) rctl $right-hand-keys)
  k (tap-hold-release-keys $tap-time $hold-time (multi k @tap) rsft $right-hand-keys)
  l (tap-hold-release-keys $tap-time $hold-time (multi l @tap) ralt $right-hand-keys)
  ; (tap-hold-release-keys $tap-time $hold-time (multi ; @tap) rmet $right-hand-keys)
)
