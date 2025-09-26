#include <m_pd.h>

static t_class *simple_tilde_class;

class simple_tilde {
  public:
    t_object xobj;
    t_sample s;
    t_float n_multiplier;
    t_outlet *x_out;
};

// ─────────────────────────────────────
static void simple_tilde_float(simple_tilde *x, t_float f1) { x->n_multiplier = f1; }

// ─────────────────────────────────────
static t_int *simple_tilde_perform(t_int *w) {
    simple_tilde *x = (simple_tilde *)(w[1]);
    t_sample *in = (t_sample *)(w[2]);
    t_sample *out = (t_sample *)(w[3]);
    int n = (int)(w[4]);

    for (int i = 0; i < n; i++) {
        out[i] = in[i] * x->n_multiplier;
    }

    return (w + 5);
}

// ─────────────────────────────────────
static void simple_tilde_dsp(simple_tilde *x, t_signal **sp) {
    dsp_add(simple_tilde_perform, 4, x, sp[0]->s_vec, sp[1]->s_vec, sp[0]->s_n);
}

// ─────────────────────────────────────
static void *simple_tilde_new(void) {
    simple_tilde *x = (simple_tilde *)pd_new(simple_tilde_class);
    x->x_out = outlet_new(&x->xobj, &s_signal);
    x->n_multiplier = 0.3;
    return x;
}

// ─────────────────────────────────────
extern "C" void simple_tilde_setup(void) {
    simple_tilde_class = class_new(gensym("simple~"), simple_tilde_new, 0,
                                   sizeof(t_object), 0, A_NULL);
    CLASS_MAINSIGNALIN(simple_tilde_class, simple_tilde, s);
    class_addmethod(simple_tilde_class, (t_method)simple_tilde_dsp, gensym("dsp"), A_CANT,
                    0);
    class_addfloat(simple_tilde_class, (t_method)simple_tilde_float);
}
