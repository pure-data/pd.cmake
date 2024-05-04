#include <m_pd.h>

static t_class *simple_class;

// ─────────────────────────────────────
static void simple_float(t_object *x, t_float f1) {
    pd_error(x, "%s got %f", __FUNCTION__, f1);
}

// ─────────────────────────────────────
static void *simple_new(void) {
    post("Creating a simple object");
    return pd_new(simple_class);
}

// ─────────────────────────────────────
extern "C" void simple_setup(void) {
    simple_class =
        class_new(gensym("simple"), simple_new, 0, sizeof(t_object), 0, A_NULL);
    class_addfloat(simple_class, simple_float);
}
