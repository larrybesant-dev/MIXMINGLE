((a, b) => {
  a[b] = a[b] || {};
})(self, "$__dart_deferred_initializers__");
$__dart_deferred_initializers__.current = function (a, b, c, $) {
  var J,
    A,
    B,
    E,
    C = {
      bz5() {
        return new C.tl(null);
      },
      tl: function tl(d) {
        this.a = d;
      },
      Qc: function Qc(d, e, f, g, h, i) {
        var _ = this;
        _.w = d;
        _.x = e;
        _.y = f;
        _.z = g;
        _.Q = !1;
        _.as = h;
        _.at = i;
        _.ax = !1;
        _.d = $;
        _.c = _.a = null;
      },
      aTK: function aTK(d) {
        this.a = d;
      },
      aTJ: function aTJ(d) {
        this.a = d;
      },
      aTI: function aTI(d, e) {
        this.a = d;
        this.b = e;
      },
      aTl: function aTl() {},
      aTn: function aTn() {},
      aTm: function aTm() {},
      aTo: function aTo(d, e) {
        this.a = d;
        this.b = e;
      },
      aTs: function aTs(d) {
        this.a = d;
      },
      aTt: function aTt(d) {
        this.a = d;
      },
      aTu: function aTu(d) {
        this.a = d;
      },
      aTp: function aTp(d) {
        this.a = d;
      },
      aTq: function aTq(d) {
        this.a = d;
      },
      aTi: function aTi(d) {
        this.a = d;
      },
      aTj: function aTj(d, e) {
        this.a = d;
        this.b = e;
      },
      aTk: function aTk(d) {
        this.a = d;
      },
      aTr: function aTr(d, e) {
        this.a = d;
        this.b = e;
      },
      aTF: function aTF(d) {
        this.a = d;
      },
      aTx: function aTx() {},
      aTy: function aTy(d) {
        this.a = d;
      },
      aTz: function aTz() {},
      aTA: function aTA() {},
      aTB: function aTB() {},
      aTC: function aTC() {},
      aTD: function aTD(d) {
        this.a = d;
      },
      aTE: function aTE(d) {
        this.a = d;
      },
      aTv: function aTv(d, e) {
        this.a = d;
        this.b = e;
      },
      aTH: function aTH() {},
      aTG: function aTG(d) {
        this.a = d;
      },
      aTw: function aTw(d) {
        this.a = d;
      },
    },
    D;
  J = c[1];
  A = c[0];
  B = c[2];
  E = c[15];
  C = a.updateHolder(c[5], C);
  D = c[19];
  C.tl.prototype = {
    W() {
      var x = $.af();
      return new C.Qc(
        new A.cI(B.ag, x),
        new A.cI(B.ag, x),
        new A.cI(B.ag, x),
        new A.bq(null, y.w),
        new A.xy(),
        A.b([], y.S),
      );
    },
  };
  C.Qc.prototype = {
    ac() {
      var x = this;
      x.au();
      x.PA();
      x.gaH().xq($.d5(), new C.aTK(x), y.v);
    },
    k() {
      var x = this,
        w = x.w,
        v = (w.L$ = $.af());
      w.K$ = 0;
      w = x.x;
      w.L$ = v;
      w.K$ = 0;
      w = x.y;
      w.L$ = v;
      w.K$ = 0;
      x.ae();
    },
    PA() {
      var x = 0,
        w = A.n(y.H),
        v = this,
        u,
        t,
        s;
      var $async$PA = A.j(function (d, e) {
        if (d === 1) return A.k(e, w);
        for (;;)
          switch (x) {
            case 0:
              try {
                u = v.gaH().ar(0, $.d5(), y.v);
                t = A.du(u, new C.aTl(), new C.aTm(), new C.aTn(), !1, !0, !1);
                if (t != null && v.c != null && !v.ax) v.I(new C.aTo(v, t));
              } catch (r) {}
              return A.l(null, w);
          }
      });
      return A.m($async$PA, w);
    },
    vE() {
      var x = 0,
        w = A.n(y.H),
        v,
        u = 2,
        t = [],
        s = [],
        r = this,
        q,
        p,
        o,
        n,
        m,
        l,
        k,
        j,
        i,
        h,
        g,
        f,
        e,
        d,
        a0,
        a1,
        a2,
        a3,
        a4,
        a5,
        a6,
        a7,
        a8,
        a9,
        b0,
        b1,
        b2,
        b3,
        b4,
        b5,
        b6,
        b7;
      var $async$vE = A.j(function (b8, b9) {
        if (b8 === 1) {
          t.push(b9);
          x = u;
        }
        for (;;)
          switch (x) {
            case 0:
              b6 = r.z.gS();
              b6 = b6 == null ? null : b6.jN();
              if (b6 !== !0) {
                x = 1;
                break;
              }
              b6 = r.w;
              q = B.c.bu(b6.a.a);
              if (r.c != null) r.I(new C.aTs(r));
              u = 4;
              k = r.gaH();
              x = 7;
              return A.h(k.ar(0, $.d5().ghs(), y.B), $async$vE);
            case 7:
              p = b9;
              if (p == null) {
                b6 = A.bv("User not found");
                throw A.c(b6);
              }
              x = !J.e(q, p.f) ? 8 : 9;
              break;
            case 8:
              o = k.ar(0, $.h0(), y.s);
              x = 10;
              return A.h(o.Cb(q), $async$vE);
            case 10:
              n = b9;
              if (n) {
                b6 = r.c;
                if (b6 != null) b6.O(y.q).f.b4(B.Gf);
                r.I(new C.aTt(r));
                s = [1];
                x = 5;
                break;
              }
            case 9:
              j = p.a;
              i = p.c;
              b6 = B.c.bu(b6.a.a);
              h = B.c.bu(r.x.a.a);
              g = B.c.bu(r.y.a.a);
              f = p.w;
              e = p.x;
              d = p.y;
              a0 = p.z;
              a1 = p.e;
              a2 = p.Q;
              a3 = p.as;
              a4 = p.at;
              a5 = p.ax;
              a6 = p.ay;
              a7 = p.ch;
              a8 = p.CW;
              a9 = p.cx;
              b0 = p.cy;
              b1 = r.at;
              b2 = p.dx;
              b3 = p.id;
              b4 = p.k2;
              m = A.OK(
                d,
                p.k3,
                g,
                a0,
                a1,
                i,
                h,
                a9,
                a8,
                a3,
                a4,
                j,
                e,
                b3,
                null,
                a6,
                f,
                null,
                null,
                null,
                b4,
                null,
                null,
                null,
                b2,
                b1,
                a7,
                a2,
                b0,
                a5,
                b6,
              );
              x = 11;
              return A.h(k.ar(0, $.h0(), y.s).uB(p.a, m.ao()), $async$vE);
            case 11:
              b6 = r.c;
              if (b6 != null) {
                b6.O(y.q).f.b4(D.ack);
                b6 = r.c;
                b6.toString;
                A.aE(b6, !1).cE();
              }
              s.push(6);
              x = 5;
              break;
            case 4:
              u = 3;
              b7 = t.pop();
              l = A.P(b7);
              b6 = r.c;
              if (b6 != null)
                b6.O(y.q).f.b4(
                  A.cB(
                    null,
                    null,
                    null,
                    null,
                    null,
                    B.q,
                    null,
                    A.B(
                      "Failed to update profile: " + A.i(l),
                      null,
                      null,
                      null,
                      null,
                      null,
                      null,
                      null,
                      null,
                    ),
                    null,
                    B.K,
                    null,
                    null,
                    null,
                    null,
                    null,
                    null,
                    null,
                    null,
                    null,
                    null,
                  ),
                );
              s.push(6);
              x = 5;
              break;
            case 3:
              s = [2];
            case 5:
              u = 2;
              if (r.c != null) r.I(new C.aTu(r));
              x = s.pop();
              break;
            case 6:
            case 1:
              return A.l(v, w);
            case 2:
              return A.k(t.at(-1), w);
          }
      });
      return A.m($async$vE, w);
    },
    pE() {
      var x = 0,
        w = A.n(y.H),
        v = 1,
        u = [],
        t = [],
        s = this,
        r,
        q,
        p,
        o,
        n,
        m,
        l,
        k,
        j,
        i,
        h,
        g,
        f,
        e,
        d,
        a0,
        a1,
        a2,
        a3,
        a4,
        a5,
        a6,
        a7,
        a8,
        a9,
        b0,
        b1,
        b2,
        b3,
        b4,
        b5,
        b6,
        b7,
        b8,
        b9;
      var $async$pE = A.j(function (c0, c1) {
        if (c0 === 1) {
          u.push(c1);
          x = v;
        }
        for (;;)
          switch (x) {
            case 0:
              A.as().$1("\ud83d\udd04 _pickAvatar called");
              v = 3;
              r = null;
              A.as().$1("\ud83c\udf10 Running on web, trying gallery picker");
              v = 7;
              x = 10;
              return A.h(s.as.uk(85, 800, 800, B.ig), $async$pE);
            case 10:
              r = c1;
              k = r;
              A.as().$1("\ud83d\udcc1 Gallery picker returned: " + A.i(k == null ? null : k.b));
              v = 3;
              x = 9;
              break;
            case 7:
              v = 6;
              b8 = u.pop();
              q = A.P(b8);
              A.as().$1("\u274c Gallery picker failed: " + A.i(q));
              x = 11;
              return A.h(s.as.uk(85, 800, 800, B.o_), $async$pE);
            case 11:
              i = c1;
              r = i;
              x = 9;
              break;
            case 6:
              x = 3;
              break;
            case 9:
              x = r != null ? 12 : 13;
              break;
            case 12:
              k = r.b;
              h = r.c;
              h === $ && A.a();
              A.as().$1("\u2705 Image selected: " + k + ", path: " + h);
              if (s.c != null) s.I(new C.aTp(s));
              k = s.gaH();
              h = $.d5();
              x = 14;
              return A.h(k.ar(0, h.ghs(), y.B), $async$pE);
            case 14:
              p = c1;
              if (p == null) {
                A.as().$1("\u274c No current user found");
                k = A.bv("User not found");
                throw A.c(k);
              }
              A.as().$1("\ud83d\udc64 Current user: " + p.a);
              o = k.ar(0, $.ahk(), y.E);
              A.as().$1("\ud83d\udce4 Starting upload to storage...");
              x = 15;
              return A.h(o.oV(r, p.a), $async$pE);
            case 15:
              n = c1;
              A.as().$1("\u2705 Upload completed, URL: " + A.i(n));
              g = p.a;
              f = p.c;
              e = p.f;
              d = p.b;
              a0 = p.r;
              a1 = p.w;
              a2 = p.x;
              a3 = p.z;
              a4 = p.e;
              a5 = p.Q;
              a6 = p.as;
              a7 = p.at;
              a8 = p.ax;
              a9 = p.ay;
              b0 = p.ch;
              b1 = p.CW;
              b2 = p.cx;
              b3 = p.cy;
              b4 = p.db;
              b5 = p.dx;
              b6 = p.id;
              b7 = p.k2;
              m = A.OK(
                n,
                p.k3,
                a0,
                a3,
                a4,
                f,
                d,
                b2,
                b1,
                a6,
                a7,
                g,
                a2,
                b6,
                null,
                a9,
                a1,
                null,
                null,
                null,
                b7,
                null,
                null,
                null,
                b5,
                b4,
                b0,
                a5,
                b3,
                a8,
                e,
              );
              x = 16;
              return A.h(k.ar(0, $.h0(), y.s).uB(p.a, m.ao()), $async$pE);
            case 16:
              if (s.c != null) {
                k.j0(h);
                s.c.O(y.q).f.b4(D.acn);
              }
            case 13:
              t.push(5);
              x = 4;
              break;
            case 3:
              v = 2;
              b9 = u.pop();
              l = A.P(b9);
              A.as().$1("\u274c Error in _pickAvatar: " + A.i(l));
              k = s.c;
              if (k != null)
                k.O(y.q).f.b4(
                  A.cB(
                    null,
                    null,
                    null,
                    null,
                    null,
                    B.q,
                    null,
                    A.B(
                      "Failed to update avatar: " + A.i(l),
                      null,
                      null,
                      null,
                      null,
                      null,
                      null,
                      null,
                      null,
                    ),
                    null,
                    B.K,
                    null,
                    null,
                    null,
                    null,
                    null,
                    null,
                    null,
                    null,
                    null,
                    null,
                  ),
                );
              t.push(5);
              x = 4;
              break;
            case 2:
              t = [1];
            case 4:
              v = 1;
              if (s.c != null) s.I(new C.aTq(s));
              x = t.pop();
              break;
            case 5:
              return A.l(null, w);
            case 1:
              return A.k(u.at(-1), w);
          }
      });
      return A.m($async$pE, w);
    },
    pm() {
      var x = 0,
        w = A.n(y.H),
        v = 1,
        u = [],
        t = [],
        s = this,
        r,
        q,
        p,
        o,
        n,
        m,
        l,
        k,
        j,
        i,
        h,
        g,
        f,
        e,
        d,
        a0,
        a1,
        a2,
        a3,
        a4,
        a5,
        a6,
        a7,
        a8,
        a9,
        b0,
        b1,
        b2,
        b3,
        b4,
        b5,
        b6,
        b7,
        b8,
        b9;
      var $async$pm = A.j(function (c0, c1) {
        if (c0 === 1) {
          u.push(c1);
          x = v;
        }
        for (;;)
          switch (x) {
            case 0:
              v = 3;
              r = null;
              v = 7;
              x = 10;
              return A.h(s.as.uk(85, 1200, 1200, B.ig), $async$pm);
            case 10:
              r = c1;
              v = 3;
              x = 9;
              break;
            case 7:
              v = 6;
              b8 = u.pop();
              x = 11;
              return A.h(s.as.uk(85, 1200, 1200, B.o_), $async$pm);
            case 11:
              k = c1;
              r = k;
              x = 9;
              break;
            case 6:
              x = 3;
              break;
            case 9:
              x = r != null ? 12 : 13;
              break;
            case 12:
              if (s.c != null) s.I(new C.aTi(s));
              j = s.gaH();
              i = $.d5();
              x = 14;
              return A.h(j.ar(0, i.ghs(), y.B), $async$pm);
            case 14:
              q = c1;
              if (q == null) {
                j = A.bv("User not found");
                throw A.c(j);
              }
              p = j.ar(0, $.ahk(), y.E);
              x = 15;
              return A.h(p.oV(r, q.a), $async$pm);
            case 15:
              o = c1;
              if (s.c != null) s.I(new C.aTj(s, o));
              h = q.a;
              g = q.c;
              f = q.f;
              e = q.b;
              d = q.r;
              a0 = q.w;
              a1 = q.x;
              a2 = q.y;
              a3 = q.z;
              a4 = q.e;
              a5 = q.Q;
              a6 = q.as;
              a7 = q.at;
              a8 = q.ax;
              a9 = q.ay;
              b0 = q.ch;
              b1 = q.CW;
              b2 = q.cx;
              b3 = q.cy;
              b4 = s.at;
              b5 = q.dx;
              b6 = q.id;
              b7 = q.k2;
              n = A.OK(
                a2,
                q.k3,
                d,
                a3,
                a4,
                g,
                e,
                b2,
                b1,
                a6,
                a7,
                h,
                a1,
                b6,
                null,
                a9,
                a0,
                null,
                null,
                null,
                b7,
                null,
                null,
                null,
                b5,
                b4,
                b0,
                a5,
                b3,
                a8,
                f,
              );
              x = 16;
              return A.h(j.ar(0, $.h0(), y.s).uB(q.a, n.ao()), $async$pm);
            case 16:
              if (s.c != null) {
                j.j0(i);
                s.c.O(y.q).f.b4(B.Gg);
              }
            case 13:
              t.push(5);
              x = 4;
              break;
            case 3:
              v = 2;
              b9 = u.pop();
              m = A.P(b9);
              j = s.c;
              if (j != null)
                j.O(y.q).f.b4(
                  A.cB(
                    null,
                    null,
                    null,
                    null,
                    null,
                    B.q,
                    null,
                    A.B(
                      "Failed to add photo: " + A.i(m),
                      null,
                      null,
                      null,
                      null,
                      null,
                      null,
                      null,
                      null,
                    ),
                    null,
                    B.K,
                    null,
                    null,
                    null,
                    null,
                    null,
                    null,
                    null,
                    null,
                    null,
                    null,
                  ),
                );
              t.push(5);
              x = 4;
              break;
            case 2:
              t = [1];
            case 4:
              v = 1;
              if (s.c != null) s.I(new C.aTk(s));
              x = t.pop();
              break;
            case 5:
              return A.l(null, w);
            case 1:
              return A.k(u.at(-1), w);
          }
      });
      return A.m($async$pm, w);
    },
    vA(d) {
      return this.aBX(d);
    },
    aBX(b5) {
      var x = 0,
        w = A.n(y.H),
        v = 1,
        u = [],
        t = this,
        s,
        r,
        q,
        p,
        o,
        n,
        m,
        l,
        k,
        j,
        i,
        h,
        g,
        f,
        e,
        d,
        a0,
        a1,
        a2,
        a3,
        a4,
        a5,
        a6,
        a7,
        a8,
        a9,
        b0,
        b1,
        b2,
        b3,
        b4;
      var $async$vA = A.j(function (b6, b7) {
        if (b6 === 1) {
          u.push(b7);
          x = v;
        }
        for (;;)
          switch (x) {
            case 0:
              b2 = t.at[b5];
              t.I(new C.aTr(t, b5));
              v = 3;
              p = t.gaH();
              x = 6;
              return A.h(p.ar(0, $.d5().ghs(), y.B), $async$vA);
            case 6:
              s = b7;
              if (s == null) {
                p = A.bv("User not found");
                throw A.c(p);
              }
              o = s.a;
              n = s.c;
              m = s.f;
              l = s.b;
              k = s.r;
              j = s.w;
              i = s.x;
              h = s.y;
              g = s.z;
              f = s.e;
              e = s.Q;
              d = s.as;
              a0 = s.at;
              a1 = s.ax;
              a2 = s.ay;
              a3 = s.ch;
              a4 = s.CW;
              a5 = s.cx;
              a6 = s.cy;
              a7 = t.at;
              a8 = s.dx;
              a9 = s.id;
              b0 = s.k2;
              r = A.OK(
                h,
                s.k3,
                k,
                g,
                f,
                n,
                l,
                a5,
                a4,
                d,
                a0,
                o,
                i,
                a9,
                null,
                a2,
                j,
                null,
                null,
                null,
                b0,
                null,
                null,
                null,
                a8,
                a7,
                a3,
                e,
                a6,
                a1,
                m,
              );
              x = 7;
              return A.h(p.ar(0, $.h0(), y.s).uB(s.a, r.ao()), $async$vA);
            case 7:
              v = 9;
              x = 12;
              return A.h(p.ar(0, $.ahk(), y.E).Iu(b2), $async$vA);
            case 12:
              v = 3;
              x = 11;
              break;
            case 9:
              v = 8;
              b3 = u.pop();
              x = 11;
              break;
            case 8:
              x = 3;
              break;
            case 11:
              if (t.c != null) {
                p.j0($.d5());
                t.c.O(y.q).f.b4(D.acg);
              }
              v = 1;
              x = 5;
              break;
            case 3:
              v = 2;
              b4 = u.pop();
              q = A.P(b4);
              p = t.c;
              if (p != null)
                p.O(y.q).f.b4(
                  A.cB(
                    null,
                    null,
                    null,
                    null,
                    null,
                    B.q,
                    null,
                    A.B(
                      "Failed to remove photo: " + A.i(q),
                      null,
                      null,
                      null,
                      null,
                      null,
                      null,
                      null,
                      null,
                    ),
                    null,
                    B.K,
                    null,
                    null,
                    null,
                    null,
                    null,
                    null,
                    null,
                    null,
                    null,
                    null,
                  ),
                );
              x = 5;
              break;
            case 2:
              x = 1;
              break;
            case 5:
              return A.l(null, w);
            case 1:
              return A.k(u.at(-1), w);
          }
      });
      return A.m($async$vA, w);
    },
    G(d) {
      var x = this,
        w = null,
        v = x.gaH().b1($.d5(), y.v);
      return A.dv(
        A.cO(
          A.f4(
            A.b([A.cH(!1, D.U4, w, w, w, w, w, w, x.Q ? w : x.gaCA(), w, w)], y.p),
            w,
            w,
            !0,
            !0,
            B.r,
            w,
            1,
            w,
            w,
            0,
            !1,
            w,
            !1,
            w,
            w,
            w,
            w,
            !0,
            w,
            w,
            w,
            w,
            w,
            w,
            w,
            w,
            w,
            1,
            w,
            !0,
          ),
          B.r,
          A.du(v, new C.aTF(x), new C.aTG(x), new C.aTH(), !1, !0, !1),
          w,
          w,
        ),
      );
    },
    YI(d, e) {
      var x = null;
      return A.aa(
        A.b([A.h6(B.H, 20, B.S, B.o, x, e, x), B.aE, A.B(d, x, x, x, x, B.dV, B.a0, x, x)], y.p),
        B.k,
        B.j,
        B.h,
        0,
        B.m,
      );
    },
  };
  var z = a.updateTypes(["a6<~>()", "oB()"]);
  C.aTK.prototype = {
    $2(d, e) {
      A.aiq(e, new C.aTJ(this.a), y.g, y.P);
    },
    $S: 929,
  };
  C.aTJ.prototype = {
    $1(d) {
      var x;
      if (d != null) {
        x = this.a;
        x = x.c != null && !x.ax;
      } else x = !1;
      if (x) {
        x = this.a;
        x.I(new C.aTI(x, d));
      }
    },
    $S: 930,
  };
  C.aTI.prototype = {
    $0() {
      var x = this.a,
        w = this.b;
      x.w.ses(0, w.f);
      x.x.ses(0, w.b);
      x.y.ses(0, w.r);
      x.at = A.cZ(w.db, !0, y.N);
      x.ax = !0;
    },
    $S: 0,
  };
  C.aTl.prototype = {
    $1(d) {
      return d;
    },
    $S: 931,
  };
  C.aTn.prototype = {
    $0() {
      return null;
    },
    $S: 28,
  };
  C.aTm.prototype = {
    $2(d, e) {
      return null;
    },
    $S: 40,
  };
  C.aTo.prototype = {
    $0() {
      var x = this.a,
        w = this.b;
      x.w.ses(0, w.f);
      x.x.ses(0, w.b);
      x.y.ses(0, w.r);
      x.at = A.cZ(w.db, !0, y.N);
      x.ax = !0;
    },
    $S: 0,
  };
  C.aTs.prototype = {
    $0() {
      return (this.a.Q = !0);
    },
    $S: 0,
  };
  C.aTt.prototype = {
    $0() {
      return (this.a.Q = !1);
    },
    $S: 0,
  };
  C.aTu.prototype = {
    $0() {
      return (this.a.Q = !1);
    },
    $S: 0,
  };
  C.aTp.prototype = {
    $0() {
      return (this.a.Q = !0);
    },
    $S: 0,
  };
  C.aTq.prototype = {
    $0() {
      return (this.a.Q = !1);
    },
    $S: 0,
  };
  C.aTi.prototype = {
    $0() {
      return (this.a.Q = !0);
    },
    $S: 0,
  };
  C.aTj.prototype = {
    $0() {
      this.a.at.push(this.b);
    },
    $S: 0,
  };
  C.aTk.prototype = {
    $0() {
      return (this.a.Q = !1);
    },
    $S: 0,
  };
  C.aTr.prototype = {
    $0() {
      B.b.ln(this.a.at, this.b);
    },
    $S: 0,
  };
  C.aTF.prototype = {
    $1(d) {
      var x,
        w,
        v,
        u,
        t,
        s,
        r,
        q,
        p,
        o,
        n,
        m = null;
      if (d == null) return B.ml;
      x = A.ci(B.o, 3);
      w = A.b([new A.bF(2, B.a3, B.o.T(0.5), B.l, 15)], y.V);
      v = d.y;
      u = v.length === 0;
      t = !u ? new A.jn(v + "?t=" + Date.now(), 1, m, B.du) : m;
      u = u ? B.uU : m;
      w = A.aD(
        m,
        A.jP(B.o, t, u, new A.bm(v, y.O), 60),
        B.n,
        m,
        m,
        new A.aM(m, m, x, m, w, m, B.aG),
        m,
        m,
        m,
        m,
        m,
        m,
        m,
        m,
      );
      x = this.a;
      v = x.Q ? new C.aTx() : new C.aTy(x);
      u = y.p;
      t = A.oA(
        m,
        A.aa(
          A.b(
            [
              A.ep(
                !1,
                x.w,
                D.XI,
                !1,
                m,
                m,
                m,
                D.aoG,
                m,
                m,
                1,
                !1,
                m,
                m,
                m,
                m,
                !1,
                m,
                B.af,
                B.M,
                m,
                new C.aTz(),
              ),
              B.u,
              A.ep(
                !1,
                x.x,
                B.o0,
                !1,
                m,
                m,
                m,
                B.HJ,
                B.fl,
                m,
                1,
                !1,
                m,
                m,
                m,
                m,
                !1,
                m,
                B.af,
                B.M,
                m,
                new C.aTA(),
              ),
              B.u,
              A.ep(
                !1,
                x.y,
                D.Xy,
                !1,
                m,
                m,
                m,
                D.aol,
                m,
                m,
                3,
                !1,
                m,
                m,
                m,
                m,
                !1,
                m,
                B.af,
                B.M,
                m,
                new C.aTB(),
              ),
              B.bc,
            ],
            u,
          ),
          B.k,
          B.j,
          B.h,
          0,
          B.m,
        ),
        x.z,
      );
      s = B.mq.T(0.8);
      r = A.aV(12);
      q = A.ci(B.o.T(0.3), 1);
      p = A.b(
        [
          A.aQ(
            A.b([D.TX, new A.dF("Add Photo", x.Q ? new C.aTC() : new C.aTD(x), D.aok)], u),
            B.k,
            B.ch,
            B.h,
            0,
            m,
          ),
          B.u,
        ],
        u,
      );
      o = x.at.length;
      if (o === 0) {
        o = B.bh.T(0.2);
        n = A.aV(12);
        p.push(
          A.aD(
            m,
            D.Mn,
            B.n,
            m,
            m,
            new A.aM(o, m, A.ci(B.bh.T(0.3), 1), n, m, m, B.C),
            m,
            200,
            D.aoq,
            m,
            m,
            m,
            m,
            m,
          ),
        );
      } else p.push(A.cP(A.beK(A.a0b(0, 0.8), new C.aTE(x), o, D.aoz, m), 250, m));
      s = A.aD(
        m,
        A.aa(p, B.I, B.j, B.h, 0, B.m),
        B.n,
        m,
        m,
        new A.aM(s, m, q, r, m, m, B.C),
        m,
        m,
        D.aoA,
        m,
        B.O,
        m,
        m,
        m,
      );
      r = B.mq.T(0.8);
      q = A.aV(12);
      p = A.ci(B.o.T(0.3), 1);
      return A.im(
        A.aa(
          A.b(
            [
              w,
              B.u,
              new A.dF("Change Avatar", v, m),
              B.bc,
              t,
              s,
              B.bc,
              A.aD(
                m,
                A.aa(
                  A.b(
                    [
                      D.U7,
                      B.u,
                      A.aQ(
                        A.b(
                          [
                            x.YI("Rooms Created", B.i.l(d.ay)),
                            x.YI("Tips Received", "$" + B.i.aA(d.ax, 2)),
                          ],
                          u,
                        ),
                        B.k,
                        B.cE,
                        B.h,
                        0,
                        m,
                      ),
                    ],
                    u,
                  ),
                  B.k,
                  B.j,
                  B.h,
                  0,
                  B.m,
                ),
                B.n,
                m,
                m,
                new A.aM(r, m, p, q, m, m, B.C),
                m,
                m,
                m,
                m,
                B.O,
                m,
                m,
                m,
              ),
            ],
            u,
          ),
          B.k,
          B.j,
          B.h,
          0,
          B.m,
        ),
        m,
        B.J,
        B.bm,
        m,
        m,
        B.E,
      );
    },
    $S: 191,
  };
  C.aTx.prototype = {
    $0() {},
    $S: 0,
  };
  C.aTy.prototype = {
    $0() {
      return this.a.pE();
    },
    $S: 0,
  };
  C.aTz.prototype = {
    $1(d) {
      var x, w, v;
      if (d == null || B.c.bu(d).length === 0) return "Username cannot be empty";
      x = B.c.bu(d);
      w = x.length;
      if (w < 3) return "Username must be at least 3 characters";
      if (w > 20) return "Username must be less than 20 characters";
      v = A.eg("^[a-zA-Z0-9_.]+$", !0, !1);
      if (!v.b.test(x)) return "Username can only contain letters, numbers, underscores, and dots";
      return null;
    },
    $S: 12,
  };
  C.aTA.prototype = {
    $1(d) {
      var x, w;
      if (d == null || B.c.bu(d).length === 0) return "Email cannot be empty";
      x = A.eg("^[\\w-\\.]+@([\\w-]+\\.)+[\\w-]{2,4}$", !0, !1);
      w = B.c.bu(d);
      if (!x.b.test(w)) return "Please enter a valid email address";
      return null;
    },
    $S: 12,
  };
  C.aTB.prototype = {
    $1(d) {
      if (d != null && d.length > 500) return "Bio must be less than 500 characters";
      return null;
    },
    $S: 12,
  };
  C.aTC.prototype = {
    $0() {},
    $S: 0,
  };
  C.aTD.prototype = {
    $0() {
      return this.a.pm();
    },
    $S: 0,
  };
  C.aTE.prototype = {
    $2(d, e) {
      var x = null,
        w = A.aV(12),
        v = this.a,
        u = A.XK(B.ca, new A.jn(v.at[e], 1, x, B.du), x),
        t = A.b([new A.bF(0, B.a3, B.v.T(0.3), B.kO, 8)], y.V),
        s = A.md(
          x,
          A.hO(
            x,
            A.aD(x, D.VA, B.n, x, x, D.K0, x, x, x, x, B.k7, x, x, x),
            B.J,
            !1,
            new A.bm("removePhotoButton_" + e, y.O),
            x,
            x,
            x,
            x,
            x,
            x,
            x,
            x,
            x,
            x,
            x,
            x,
            x,
            x,
            x,
            new C.aTv(v, e),
            x,
            x,
            x,
            x,
            x,
            x,
          ),
          x,
          x,
          x,
          8,
          8,
          x,
        ),
        r = A.aV(16);
      return A.aD(
        x,
        A.fV(
          B.bg,
          A.b(
            [
              s,
              A.md(
                8,
                A.aD(
                  x,
                  A.B("" + (e + 1) + " / " + v.at.length, x, x, x, x, B.j7, B.a0, x, x),
                  B.n,
                  x,
                  x,
                  new A.aM(B.a5, x, x, r, x, x, B.C),
                  x,
                  x,
                  x,
                  x,
                  B.eS,
                  x,
                  x,
                  x,
                ),
                x,
                x,
                8,
                8,
                x,
                x,
              ),
            ],
            y.p,
          ),
          B.q,
          B.b4,
          x,
        ),
        B.n,
        x,
        x,
        new A.aM(x, u, x, w, t, x, B.C),
        x,
        x,
        x,
        B.ec,
        x,
        x,
        x,
        x,
      );
    },
    $S: 933,
  };
  C.aTv.prototype = {
    $0() {
      return this.a.vA(this.b);
    },
    $S: 0,
  };
  C.aTH.prototype = {
    $0() {
      return D.TP;
    },
    $S: z + 1,
  };
  C.aTG.prototype = {
    $2(d, e) {
      var x = null;
      return A.bY(
        A.aa(
          A.b(
            [
              D.Ua,
              B.U,
              A.h6(B.N, 14, x, x, x, J.bQ(d), x),
              B.u,
              new A.dF("Retry", new C.aTw(this.a), x),
            ],
            y.p,
          ),
          B.k,
          B.a7,
          B.h,
          0,
          B.m,
        ),
        x,
        x,
      );
    },
    $S: 29,
  };
  C.aTw.prototype = {
    $0() {
      return this.a.gaH().j0($.d5());
    },
    $S: 0,
  };
  (function installTearOffs() {
    var x = a._instance_0u;
    x(C.Qc.prototype, "gaCA", "vE", 0);
  })();
  (function inheritance() {
    var x = a.inherit,
      w = a.inheritMany;
    x(C.tl, A.n_);
    x(C.Qc, A.lN);
    w(A.kN, [C.aTK, C.aTm, C.aTE, C.aTG]);
    w(A.iH, [C.aTJ, C.aTl, C.aTF, C.aTz, C.aTA, C.aTB]);
    w(A.jQ, [
      C.aTI,
      C.aTn,
      C.aTo,
      C.aTs,
      C.aTt,
      C.aTu,
      C.aTp,
      C.aTq,
      C.aTi,
      C.aTj,
      C.aTk,
      C.aTr,
      C.aTx,
      C.aTy,
      C.aTC,
      C.aTD,
      C.aTv,
      C.aTH,
      C.aTw,
    ]);
  })();
  A.o3(b.typeUniverse, JSON.parse('{"tl":{"Q":[],"d":[]},"Qc":{"Y":["tl"]}}'));
  var y = (function rtii() {
    var x = A.T;
    return {
      v: x("bt<co?>"),
      s: x("lR"),
      B: x("a6<co?>"),
      V: x("C<bF>"),
      S: x("C<o>"),
      p: x("C<d>"),
      w: x("bq<xg>"),
      P: x("bg"),
      E: x("uM"),
      N: x("o"),
      O: x("bm<o>"),
      q: x("rw"),
      g: x("co?"),
      H: x("~"),
    };
  })();
  (function constants() {
    var x = a.makeConstList;
    D.K0 = new A.aM(B.a5, null, null, null, null, null, B.aG);
    D.Vc = new A.aX(58550, "MaterialIcons", !1);
    D.VM = new A.aP(D.Vc, 48, B.bh, null, null, null);
    D.alR = new A.S(
      "No photos yet. Add some photos to showcase your style!",
      null,
      B.dr,
      B.a0,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
    );
    D.a_u = x([D.VM, B.U, D.alR], y.p);
    D.Px = new A.jR(B.E, B.a7, B.h, B.k, null, B.m, null, 0, D.a_u, null);
    D.Mn = new A.cT(B.R, null, null, D.Px, null);
    D.TP = new E.oB("Loading profile...", null);
    D.TX = new A.cL("My Photos", 18, null, B.H, B.o, null, null, null);
    D.U4 = new A.cL("Save", 16, null, B.o, B.o, null, null, null);
    D.U7 = new A.cL("Your Stats", 18, null, B.H, B.o, null, null, null);
    D.Ua = new A.cL("Failed to load profile", 18, null, B.o, B.o, null, null, null);
    D.VA = new A.aP(B.ko, 18, B.e, null, null, null);
    D.UO = new A.aX(57791, "MaterialIcons", !1);
    D.W0 = new A.aP(D.UO, null, B.H, null, null, null);
    D.Xy = new A.cy(
      null,
      null,
      null,
      "Bio (optional)",
      null,
      null,
      null,
      null,
      null,
      null,
      "Tell us about yourself...",
      null,
      null,
      null,
      null,
      null,
      !0,
      !0,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      D.W0,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      B.ac,
      !0,
      null,
      null,
      null,
      null,
    );
    D.XI = new A.cy(
      null,
      null,
      null,
      "Username",
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      !0,
      !0,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      B.uT,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      B.ac,
      !0,
      null,
      null,
      null,
      null,
    );
    D.alr = new A.S(
      "Photo removed successfully",
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
    );
    D.acg = new A.df(
      D.alr,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      B.K,
      !1,
      null,
      null,
      null,
      B.q,
      null,
    );
    D.als = new A.S(
      "Profile updated successfully",
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
    );
    D.ack = new A.df(
      D.als,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      B.K,
      !1,
      null,
      null,
      null,
      B.q,
      null,
    );
    D.aj4 = new A.S(
      "Avatar updated successfully",
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
    );
    D.acn = new A.df(
      D.aj4,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      B.K,
      !1,
      null,
      null,
      null,
      B.q,
      null,
    );
    D.aok = new A.bm("addPhotoButton", y.O);
    D.aol = new A.bm("bioField", y.O);
    D.aoq = new A.bm("emptyPhotosMessage", y.O);
    D.aoz = new A.bm("photoCarousel", y.O);
    D.aoA = new A.bm("photoCarouselContainer", y.O);
    D.aoG = new A.bm("usernameField", y.O);
  })();
};
((a) => {
  a["mD9RXL9r6NqINHTQXSMTLflxD4U="] = a.current;
})($__dart_deferred_initializers__);
