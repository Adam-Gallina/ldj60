extends CPUParticles3D
class_name EffectController

func play_once():
    emitting = true

    await finished

    queue_free()