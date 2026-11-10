<?php
$logo_app = (isset($setting->logo_kanan) && !empty($setting->logo_kanan)) ? base_url() . $setting->logo_kanan : base_url('assets/img/necis_logo.png');
$app_title = (!empty($setting->nama_aplikasi)) ? $setting->nama_aplikasi : 'Necis CBT by Dado';
$school_subtitle = (!empty($setting->sekolah)) ? $setting->sekolah : 'SMK NEGERI CIPATUJAH';
?>
<div class="modern-login-wrapper">
    <div class="modern-login-card">
        <!-- Brand & School Header -->
        <div class="text-center mb-4">
            <div class="modern-login-logo">
                <img src="<?= $logo_app ?>" alt="Logo">
            </div>
            <h4 class="modern-login-title"><?= $app_title ?></h4>
            <p class="modern-login-subtitle mb-0"><?= $school_subtitle ?></p>
        </div>

        <!-- Feedback & Error Message -->
        <div id="infoMessage"><?php echo $message; ?></div>

        <!-- Login Form -->
        <?= form_open("auth/cek_login", array('id' => 'login')); ?>
        
        <div class="modern-input-group has-feedback">
            <span class="fas fa-user modern-input-icon"></span>
            <?= form_input($identity, '', 'required placeholder="Username atau NISN"'); ?>
            <div class="help-block text-danger font-weight-bold mt-1 text-sm"></div>
        </div>

        <div class="modern-input-group has-feedback">
            <span class="fas fa-lock modern-input-icon"></span>
            <?= form_input($password, '', 'required placeholder="Password"'); ?>
            <span id="toggle-password" class="fas fa-eye-slash modern-input-toggle"></span>
            <div class="help-block text-danger font-weight-bold mt-1 text-sm"></div>
        </div>

        <div class="d-flex justify-content-between align-items-center mb-4">
            <div class="custom-control custom-checkbox">
                <input type="checkbox" class="custom-control-input" id="cbt-only" name="cbt-only" value="1" checked="checked">
                <label class="custom-control-label font-weight-normal text-muted" for="cbt-only" style="cursor: pointer; font-size: 14px;">
                    Mode Ujian (CBT Only)
                </label>
            </div>
        </div>

        <div class="form-group mb-0">
            <?= form_submit('submit', lang('login_submit_btn'), array('id' => 'submit', 'class' => 'modern-login-btn')); ?>
        </div>

        <?= form_close(); ?>
    </div>
</div>

<script src="<?= base_url() ?>/assets/app/js/jquery.backstretch.js"></script>
<script type="text/javascript">
    let base_url = '<?=base_url();?>';
    var img = ["wall1.jpg", "wall2.png", "wall3.jpg"];

    $.backstretch([
        base_url + 'assets/img/' + img[0],
        base_url + 'assets/img/' + img[1],
        base_url + 'assets/img/' + img[2]
    ], {
        fade: 1000,
        duration: 10000
    });

    $(document).ready(function(){
        $('#myCarousel').carousel({
            interval: 1000 * 2,
            pause: 'none'
        });

        $('form#login input').on('change', function(){
            $(this).parent().removeClass('has-error');
            $(this).next().next().text('');
        });

        $('form#login').on('submit', function(e){
            e.preventDefault();
            e.stopImmediatePropagation();

            var infobox = $('#infoMessage');
            infobox.html('<div class="alert alert-info py-2 px-3 text-center mb-3"><i class="fas fa-spinner fa-spin mr-2"></i>Memverifikasi akun...</div>');

            var btnsubmit = $('#submit');
            btnsubmit.attr('disabled', 'disabled').val('Memproses...');

            const arrForm = $(this).serializeArray()
            const cbtOnly = arrForm.find(function (obj) {
                return obj.name === 'cbt-only'
            })
            localStorage.setItem('necisCBT.login', cbtOnly !== undefined ? '1' : '0')
            localStorage.setItem('saduciCBT.login', cbtOnly !== undefined ? '1' : '0')
            localStorage.setItem('garudaCBT.login', cbtOnly !== undefined ? '1' : '0')

            $.ajax({
                url: $(this).attr('action'),
                type: 'POST',
                data: $(this).serialize(),
                success: function(data){
                    infobox.empty();
                    btnsubmit.removeAttr('disabled').val('Login');
                    console.log('login', data);
                    if(data.status){
                        infobox.html('<div class="alert alert-success py-2 px-3 text-center mb-3"><i class="fas fa-check-circle mr-2"></i>Login berhasil! Mengalihkan...</div>');

                        const isLogin = localStorage.getItem('necisCBT.login') || localStorage.getItem('saduciCBT.login') || localStorage.getItem('garudaCBT.login')
                        const isCbtMode = isLogin ? isLogin === '1' : false
                        let go = base_url + data.url;
                        if (isCbtMode && data.role === 'siswa') {
                            go = 'siswa/cbt'
                        }
                        window.location.href = go;
                    }else{
                        if(data.invalid){
                            $.each(data.invalid, function(key, val){
                                $('[name="'+key+'"]').parent().addClass('has-error');
                                $('[name="'+key+'"]').siblings('.help-block').text(val);
                                if(val == ''){
                                    $('[name="'+key+'"]').parent().removeClass('has-error');
                                    $('[name="'+key+'"]').siblings('.help-block').text('');
                                }
                            });
                        }
                        if(data.failed){
                            infobox.html('<div class="alert alert-danger py-2 px-3 text-center mb-3"><i class="fas fa-exclamation-triangle mr-2"></i>' + data.failed + '</div>');
                        }
                    }
                },
                error: function() {
                    btnsubmit.removeAttr('disabled').val('Login');
                    infobox.html('<div class="alert alert-danger py-2 px-3 text-center mb-3"><i class="fas fa-exclamation-circle mr-2"></i>Gagal terhubung ke server. Coba lagi.</div>');
                }
            });
        });

        $('#toggle-password').on('click', function (e) {
            const type = $('#password').attr('type') === 'password' ? 'text' : 'password';
            $('#password').attr('type', type);
            $(this).toggleClass('fa-eye-slash fa-eye');
        });
    });
</script>
