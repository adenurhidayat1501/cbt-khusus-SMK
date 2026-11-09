<div class="info-box bg-transparent shadow-none align-items-center mb-3">
    <img class="avatar mr-3" src="<?= base_url($siswa->foto) ?>" width="84" height="84" style="border: 3px solid rgba(255,255,255,0.8); box-shadow: 0 4px 15px rgba(0,0,0,0.3); border-radius: 50%; object-fit: cover;">
    <div class="info-box-content">
        <h4 class="info-box-text text-white text-wrap mb-1 font-weight-bold" style="letter-spacing: -0.01em;"><?= $siswa->nama ?></h4>
        <span class="info-box-text text-white-50" style="font-size: 13px;"><?= $siswa->nis ?> &bull; <?= $siswa->nama_kelas ?></span>
    </div>
</div>

<script>
    $(`.avatar`).each(function () {
        $(this).on("error", function () {
            var src = $(this).attr('src').replace('profiles', 'foto_siswa');
            $(this).attr("src", src);
            $(this).on("error", function () {
                $(this).attr("src", base_url + 'assets/img/siswa.png');
            });

        });
    });
</script>
