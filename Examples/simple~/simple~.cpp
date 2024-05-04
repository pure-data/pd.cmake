#include <m_pd.h>

static t_class *simple_tilde_class;

class SimpleTilde {
  public:
    t_object xObj;
    t_sample xSample;
    t_float nMultiplier;
    t_outlet *xOutlet;
};

// ─────────────────────────────────────
static void SimpleFloat(SimpleTilde *x, t_float f1) { x->nMultiplier = f1; }

// ─────────────────────────────────────
static t_int *SimplePerform(t_int *w) {
    SimpleTilde *x = (SimpleTilde *)(w[1]);
    t_sample *in = (t_sample *)(w[2]);
    t_sample *out = (t_sample *)(w[3]);
    int n = (int)(w[4]);

    for (int i = 0; i < n; i++) {
        out[i] = in[i] * x->nMultiplier;
    }

    return (w + 5);
}

// ─────────────────────────────────────
static void AddDsp(SimpleTilde *x, t_signal **sp) {
    dsp_add(SimplePerform, 4, x, sp[0]->s_vec, sp[1]->s_vec, sp[0]->s_n);
}

// ─────────────────────────────────────
static void *simple_tilde_new(void) {
    SimpleTilde *x = (SimpleTilde *)pd_new(simple_tilde_class);
    x->xOutlet = outlet_new(&x->xObj, &s_signal);
    x->nMultiplier = 0.3;
    return x;
}

// ─────────────────────────────────────
extern "C" void simple_tilde_setup(void) {
    simple_tilde_class = class_new(gensym("simple~"), simple_tilde_new, 0,
                                   sizeof(t_object), 0, A_NULL);
    CLASS_MAINSIGNALIN(simple_tilde_class, SimpleTilde, xSample);
    class_addmethod(simple_tilde_class, (t_method)AddDsp, gensym("dsp"), A_CANT,
                    0);
    class_addfloat(simple_tilde_class, (t_method)SimpleFloat);
}
