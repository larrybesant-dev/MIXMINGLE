((a, b) => {
  a[b] = a[b] || {};
})(self, "$__dart_deferred_initializers__");
$__dart_deferred_initializers__.current = function (a, b, c, $) {
  var B,
    D,
    A = {
      bbI: function bbI() {},
      bbH: function bbH() {},
      bbG: function bbG() {},
      bo2(d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, a0, a1) {
        return new A.eY(l, q, j, r, m, h, a0, i, w, s, v, g, k, x, a1, n, t, p, f, d, u, o, e);
      },
      bCN(a3) {
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
          m,
          l,
          k,
          j,
          i,
          h,
          g,
          f,
          e = "isActive",
          d = a3.h(0, "id"),
          a0 = a3.h(0, "name"),
          a1 = a3.h(0, "hostId"),
          a2 = a3.h(0, "participantIds");
        if (a2 == null) a2 = a3.h(0, "participants");
        if (a2 == null) a2 = [];
        x = y.g;
        a2 = B.cZ(a2, !0, x);
        w = a3.h(0, e);
        if (w == null) w = a3.h(0, "isLive");
        if (w == null) w = !1;
        v = B.n1(a3.h(0, "createdAt"));
        u = a3.h(0, "title");
        if (u == null) u = a3.h(0, "name");
        if (u == null) u = "";
        t = a3.h(0, "description");
        if (t == null) t = "";
        s = a3.h(0, "tags");
        s = B.cZ(s == null ? [] : s, !0, x);
        r = a3.h(0, "privacy");
        if (r == null) r = "public";
        q = a3.h(0, "status");
        if (q == null) q = "live";
        p = a3.h(0, "category");
        if (p == null) p = "";
        o = a3.h(0, "hostName");
        if (o == null) o = "";
        n = a3.h(0, "thumbnailUrl");
        m = a3.h(0, "viewerCount");
        if (m == null) m = 0;
        l = a3.h(0, "isLive");
        if (l == null) l = a3.h(0, e);
        if (l == null) l = !1;
        k = D.b.ix(C.ZT, new A.aEc(a3), new A.aEd());
        j = a3.h(0, "moderators");
        j = B.cZ(j == null ? [] : j, !0, x);
        i = a3.h(0, "bannedUsers");
        i = B.cZ(i == null ? [] : i, !0, x);
        h = a3.h(0, "agoraChannelName");
        g = a3.h(0, "speakers");
        g = B.cZ(g == null ? [] : g, !0, x);
        f = a3.h(0, "listeners");
        x = B.cZ(f == null ? [] : f, !0, x);
        f = a3.h(0, "allowSpeakerRequests");
        return A.bo2(
          h,
          f == null ? !0 : f,
          i,
          p,
          v,
          t,
          a1,
          o,
          d,
          w,
          l,
          x,
          j,
          a0,
          a2,
          r,
          k,
          g,
          q,
          s,
          n,
          u,
          m,
        );
      },
      p1: function p1(d, e) {
        this.a = d;
        this.b = e;
      },
      eY: function eY(d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, a0, a1) {
        var _ = this;
        _.a = d;
        _.b = e;
        _.c = f;
        _.d = g;
        _.e = h;
        _.f = i;
        _.r = j;
        _.w = k;
        _.x = l;
        _.y = m;
        _.z = n;
        _.Q = o;
        _.as = p;
        _.at = q;
        _.ax = r;
        _.ay = s;
        _.ch = t;
        _.CW = u;
        _.cx = v;
        _.cy = w;
        _.db = x;
        _.dx = a0;
        _.dy = a1;
      },
      aEc: function aEc(d) {
        this.a = d;
      },
      aEd: function aEd() {},
    },
    C;
  B = c[0];
  D = c[2];
  A = a.updateHolder(c[14], A);
  C = c[21];
  A.p1.prototype = {
    E() {
      return "RoomType." + this.b;
    },
  };
  A.eY.prototype = {
    ao() {
      var x = this;
      return B.W(
        [
          "id",
          x.a,
          "name",
          x.b,
          "hostId",
          x.c,
          "participantIds",
          x.d,
          "isActive",
          x.e,
          "createdAt",
          x.f.mp(),
          "title",
          x.r,
          "description",
          x.w,
          "tags",
          x.x,
          "privacy",
          x.y,
          "status",
          x.z,
          "category",
          x.Q,
          "hostName",
          x.as,
          "thumbnailUrl",
          x.at,
          "viewerCount",
          x.ax,
          "isLive",
          x.ay,
          "roomType",
          D.b.ga7(x.ch.E().split(".")),
          "moderators",
          x.CW,
          "bannedUsers",
          x.cx,
          "agoraChannelName",
          x.cy,
          "speakers",
          x.db,
          "listeners",
          x.dx,
          "allowSpeakerRequests",
          x.dy,
        ],
        y.g,
        y.b,
      );
    },
    gbb(d) {
      return this.a;
    },
  };
  var z = a.updateTypes(["N(p1)", "p1()"]);
  A.bbI.prototype = {
    $1(d) {
      var x = d.b1($.h0(), y.f).a.af("rooms").eA();
      return new B.ct(new A.bbH(), x, x.$ti.i("ct<aN.T,A<eY>>"));
    },
    $S: 946,
  };
  A.bbH.prototype = {
    $1(d) {
      var x = d.gce(),
        w = B.a0(x).i("X<1,eY>");
      x = B.a_(new B.X(x, new A.bbG(), w), w.i("ag.E"));
      return x;
    },
    $S: 947,
  };
  A.bbG.prototype = {
    $1(d) {
      var x = d.dZ(0);
      x.toString;
      y.i.a(x);
      x.m(0, "id", D.b.ga7(d.b.b.a));
      return A.bCN(x);
    },
    $S: 948,
  };
  A.aEc.prototype = {
    $1(d) {
      var x = d.E(),
        w = this.a.h(0, "roomType");
      return x === "RoomType." + B.i(w == null ? "text" : w);
    },
    $S: z + 0,
  };
  A.aEd.prototype = {
    $0() {
      return C.oV;
    },
    $S: z + 1,
  };
  (function inheritance() {
    var x = a.inheritMany,
      w = a.inherit;
    x(B.iH, [A.bbI, A.bbH, A.bbG, A.aEc]);
    w(A.p1, B.A_);
    w(A.eY, B.v);
    w(A.aEd, B.jQ);
  })();
  var y = { f: B.T("lR"), i: B.T("a7<o,@>"), g: B.T("o"), b: B.T("@") };
  (function constants() {
    var x = a.makeConstList;
    C.oV = new A.p1(0, "text");
    C.a96 = new A.p1(1, "voice");
    C.a97 = new A.p1(2, "video");
    C.ZT = x([C.oV, C.a96, C.a97], B.T("C<p1>"));
  })();
  (function lazyInitializers() {
    var x = a.lazyFinal;
    x($, "bUy", "bjK", () => B.zm(new A.bbI(), B.T("A<eY>")));
  })();
};
((a) => {
  a["uBAtibnyOFyL4Pf/QPRxCsGCyfU="] = a.current;
})($__dart_deferred_initializers__);
