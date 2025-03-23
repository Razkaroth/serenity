
;; -*- TIMINGS -*-
(defvar
  tap-time 150
  tap-timeout 200

  ;; Added variables for home row mods
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

(defalias
  spc (tap-hold 150 200 spc (layer-while-held lyrs))
  lyBk (layer-switch base)
  sym (layer-switch symbols)
  akt (layer-switch actions)
  )

(defsrc
  esc   1    2    3    4    5    6    7    8    9    0    -    =    grv  bspc
  tab   q    w    e    r    t    y    u    i    o    p    [    ]    \    del
  caps  a    s    d    f    g    h    j    k    l    ;    '    ret       pgup
  lsft  z    x    c    v    b    n    m    ,    .    /    rsft      ▲    pgdn
  lctl  lmet lalt           spc            ralt rmet rctl      ◀    ▼    ▶
)

(deflayer base

;;   esc   1     2     3     4     5     6     7     8     9     0     -     =     grv   bspc
     esc   1     2     3     4     5     6     7     8     9     0     -     =     grv   bspc

;;   tab   q     w     e     r     t     y     u     i     o     p     [     ]     \     del
     tab   q     w     e     r     t     y     u     i     o     p     [     ]     \     del

;;   caps  a     s     d     f     g     h     j     k     l     ;     '     ret         pgup
     esc   a     s     d     f     g     h     j     k     l     ;     '     ret         home

;;   lsft  z     x     c     v     b     n     m     ,     .     /     rsft        ▲     pgdn
     lsft  z     x     c     v     b     n     m     ,     .     /     rsft        ▲     end

;;   lctl  lmet  lalt             spc               ralt  rmet  rctl         ◀     ▼     ▶
     lctl  lmet  lalt             @spc              ralt  rmet  rctl         ◀     ▼     ▶
)

;; ----------------- LAYERS -----------------

(defalias
  ;; nvim complete alt tab
  c A-tab
  qt (macro ' spc)
  dq (macro S-' spc)
  )

(deflayer lyrs
;;   esc   1     2     3     4     5     6     7     8     9     0     -     =     grv   bspc
     esc   f1    f2    f3    f4    f5    f6    f7    f8    f9    f10   f11   f12   _     _

;;   tab   q     w     e     r     t     y     u     i     o     p     [     ]     \     del
     _     _     _    ret   lrld   @c    home  pgdn  pgup  end    _     _     _     _     _

;;   caps  a     s     d     f     g     h     j     k     l     ;     '     ret         pgup
     caps @akt  @sym  bspc  del   spc    ◀     ▼     ▲     ▶     _     _     _           _

;;   lsft  z     x     c     v     b     n     m     ,     .     /     rsft        ▲     pgdn
     _    S-,    =    S-.   @qt   @dq   @op   @ob    _     _     _     _           _     _

;;   lctl  lmet  lalt             spc               ralt  rmet  rctl         ◀     ▼     ▶
     _     _     _                 _                 _     _     _           _     _     _
)

;; ----------------- SYMBOLS -----------------

(defalias
  ;; open parenthesis
  op S-9
  ;; close parenthesisnext
  cp S-0
  ;; open  curly brace
  ob S-[
  ;; close curly brace
  cb S-]
  ;; pipe (shift + backslash)
  pp S-\
  ;; at symbol (shift + 2)
  at S-2
  ;; dollar sign (shift + 4)
  ds S-4
  ;; percent sign (shift + 5)
  ps S-5
  ;; caret (shift + 6)
  ct S-6
  ;; ampersand (shift + 7)
  am S-7
  ;; asterisk (shift + 8)
  ast S-8
  ;; plus (shift + equals)
  pl S-=
  ;; underscore (shift + hyphen)
  us S--
  ;; pipe (shift + backslash)
  pipe S-\
 )

(deflayer symbols
;;   esc   1     2     3     4     5     6     7     8     9     0     -     =     grv   bspc
     _    S-1   S-2   S-3   S-4   S-5   S-6   S-7   S-8   S-9   S-0   S--   S-=  S-grv   _

;;   tab   q     w     e     r     t     y     u     i     o     p     [     ]     \     del
     _     1     2     3     4     5     6     7     8     9     0     _     _     _     _

;;   caps  a     s     d     f     g     h     j     k     l     ;     '     ret         pgup
     @lyBk _     _     =     -    @us    [    @op   @cp    ]     _     _     _           _

;;   lsft  z     x     c     v     b     n     m     ,     .     /     rsft        ▲     pgdn
     _     \     _    S-=   @us  @lyBk  @ob   @cb    ,     .     /     _           _     _

;;   lctl  lmet  lalt             spc               ralt  rmet  rctl         ◀     ▼     ▶
     _     _     _               @spc                _     _     _           _     _     _
)




;; ----------------- action LAYER -----------------


(deflayer actions
;;   esc   1     2     3     4     5     6     7     8     9     0     -     =     grv   bspc
     _     _     _     _     _     _     _     _     _     _     _     _     _     _     _

;;   tab   q     w     e     r     t     y     u     i     o     p     [     ]     \     del
     _     _     _     _     _     _     _     _     _     _     pp     _     _     _     _

;;   caps  a     s     d     f     g     h     j     k     l     ;     '     ret         pgup
     @lyBk _     _     _     _     _    prev voldwn volu  next   _     _     _           _

;;   lsft  z     x     c     v     b     n     m     ,     .     /     rsft        ▲     pgdn
     _     _     _     _     _   @lyBk     _    mute   _     _     _     _           _     _

;;   lctl  lmet  lalt             spc               ralt  rmet  rctl         ◀     ▼     ▶
     _     _     _               @spc               _     _     _           _     _     _
)




;; ----------------- BLANK LAYER -----------------


(deflayer blank
;;   esc   1     2     3     4     5     6     7     8     9     0     -     =     grv   bspc
     _     _     _     _     _     _     _     _     _     _     _     _     _     _     _

;;   tab   q     w     e     r     t     y     u     i     o     p     [     ]     \     del
     _     _     _     _     _     _     _     _     _     _     _     _     _     _     _

;;   caps  a     s     d     f     g     h     j     k     l     ;     '     ret         pgup
     @lyBk _     _     _     _     _     _     _     _     _     _     _     _           _

;;   lsft  z     x     c     v     b     n     m     ,     .     /     rsft        ▲     pgdn
     _     _     _     _     _   @lyBk      _     _     _     _     _     _           _     _

;;   lctl  lmet  lalt             spc               ralt  rmet  rctl         ◀     ▼     ▶
     _     _     _               @spc                 _     _     _           _     _     _
)




;; ----------------- HOMEROW -----------------

(deflayer nomods
  esc   1    2    3    4    5    6    7    8    9    0    -    =    grv  bspc
  tab   q    w    e    r    t    y    u    i    o    p    [    ]    \    del
  esc   a    s    d    f    g    h    j    k    l    ;    '    ret       pgup
  lsft  z    x    c    v    b    n    m    ,    .    /    rsft      ▲    pgdn
  lctl  lmet lalt           spc            ralt rmet rctl      ◀    ▼    ▶
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
  d (tap-hold-release-keys $tap-time $hold-time (multi d @tap) lctl $left-hand-keys)
  f (tap-hold-release-keys $tap-time $hold-time (multi f @tap) lsft $left-hand-keys)
  j (tap-hold-release-keys $tap-time $hold-time (multi j @tap) lsft $right-hand-keys)
  k (tap-hold-release-keys $tap-time $hold-time (multi k @tap) lctl $right-hand-keys)
  l (tap-hold-release-keys $tap-time $hold-time (multi l @tap) lalt $right-hand-keys)
  ; (tap-hold-release-keys $tap-time $hold-time (multi ; @tap) lmet $right-hand-keys)
)

;; ----------------- SYMBOLS -----------------



;; old mappings
;; (deflayer fn
;;   caps @grv  f1     f2      f3      f4      f5      f6    f7       f8     f9   f10  f11  f12  ins
;;   tab   q    w      end     lrld    @tmx    y       u     @i       o      pp   @op  @cp  \    del
;;    _    a    s      bspc    home    g       ◀       ▼     ▲        ▶      @n   '    ret       pgup
;;   lsft  z    x      C-S-c   C-S-v   prev    next    mute  voldwn   volu   /    rsft           pgdn
;;   lctl  lmet lalt            ret            ralt    rmet  rctl
;; )
