#include <m_pd.h>

static t_class *c_sum_class;

class c_sum {
  public:
    t_object x_obj;
    t_float x_in1;
    t_float x_in2;
    t_inlet *x_inlet2;
    t_outlet *x_outlet;
};

void sum_float(c_sum *x, t_float f) { outlet_float(x->x_outlet, f + x->x_in2); }

void *sum_new(t_floatarg f1, t_floatarg f2) {
    c_sum *x = (c_sum *)pd_new(c_sum_class);
    x->x_in1 = f1;
    x->x_in2 = f2;
    x->x_inlet2 = floatinlet_new(&x->x_obj, &x->x_in2);
    x->x_outlet = outlet_new(&x->x_obj, &s_float);
    return x;
}

void sum_free(c_sum *x) { freebytes(x, sizeof(c_sum)); }

extern "C" void sum_setup(void) {
    c_sum_class =
        class_new(gensym("sum"), (t_newmethod)sum_new, (t_method)sum_free,
                  sizeof(c_sum), CLASS_DEFAULT, A_DEFFLOAT, A_DEFFLOAT, 0);
    class_addfloat(c_sum_class, sum_float);
}
