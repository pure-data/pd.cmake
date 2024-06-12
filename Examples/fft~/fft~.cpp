#include <fftw3.h>
#include <m_pd.h>

static t_class *fftw3_tilde_class;

class FFTTilde {
  public:
    t_object xObj;
    t_sample xSample;

    fftwf_plan plan; // Add fftw3f plan here
    float *input;
    fftwf_complex *output;

    t_outlet *real;
    t_outlet *imag;

    ~FFTTilde() {
        fftwf_destroy_plan(plan);
        fftwf_free(input);
        fftwf_free(output);
    }
};

// ─────────────────────────────────────
static t_int *PerformRoutine(t_int *w) {
    FFTTilde *x = (FFTTilde *)(w[1]);
    t_sample *in = (t_sample *)(w[2]);
    t_sample *real = (t_sample *)(w[3]);
    t_sample *imag = (t_sample *)(w[4]);
    int n = (int)(w[5]);

    // Copy input to FFTW input array
    for (int i = 0; i < n; i++) {
        x->input[i] = in[i];
    }

    // Perform FFT
    fftwf_execute_dft_r2c(x->plan, x->input, x->output);

    // Copy FFTW output to real and imag arrays
    for (int i = 0; i < n / 2 + 1; i++) {
        real[i] = x->output[i][0];
        imag[i] = x->output[i][1];
    }

    return (w + 6);
}

// ─────────────────────────────────────
static void AddDsp(FFTTilde *x, t_signal **sp) {

    // Allocate/load FFTW resources
    if (x->input != nullptr) {
        fftwf_destroy_plan(x->plan);
        fftwf_free(x->input);
        fftwf_free(x->output);
    }

    x->input = (float *)fftwf_malloc(sizeof(float) * sp[0]->s_n);
    x->output =
        (fftwf_complex *)fftwf_malloc(sizeof(fftwf_complex) * (sp[0]->s_n));
    x->plan =
        fftwf_plan_dft_r2c_1d(sp[0]->s_n, x->input, x->output, FFTW_ESTIMATE);

    dsp_add(PerformRoutine, 5, x, sp[0]->s_vec, sp[1]->s_vec, sp[2]->s_vec,
            sp[0]->s_n);
}

// ─────────────────────────────────────
static void *FFTNew(void) {
    FFTTilde *x = (FFTTilde *)pd_new(fftw3_tilde_class);
    x->real = outlet_new(&x->xObj, &s_signal);
    x->imag = outlet_new(&x->xObj, &s_signal);
    return x;
}

// ─────────────────────────────────────
static void *FFTFree(FFTTilde *x) {
    fftwf_destroy_plan(x->plan);
    fftwf_free(x->input);
    fftwf_free(x->output);
    freebytes(x, sizeof(FFTTilde));
    return nullptr;
}

// ─────────────────────────────────────
extern "C" void myfft_tilde_setup() {
    fftw3_tilde_class = class_new(gensym("myfft~"), (t_newmethod)FFTNew, 0,
                                  sizeof(FFTTilde), CLASS_DEFAULT, A_NULL);
    CLASS_MAINSIGNALIN(fftw3_tilde_class, FFTTilde, xSample);
    class_addmethod(fftw3_tilde_class, (t_method)AddDsp, gensym("dsp"), A_CANT,
                    0);
}
