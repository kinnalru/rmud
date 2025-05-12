module C7i

  SPELL_FAILURE = 'Ты не смог сосредоточиться.'
  SPELLS = {
    armor:        {
      name:    'armor',
      success: ['Hа тебе уже есть магическая защита.', 'Ты чувствуешь, как что-то защищает тебя.']
    },
    cure_light:   {
      name:    'cure light',
      success: ['Ты уже здоров, как бык.', 'Ты чувствуешь себя слегка лучше!']
    },
    cure_serious: {
      name: 'cure serious',
      success: ['Ты уже здоров, как бык.', 'Ты чувствуешь себя лучше!']
    },
    detect_magic: {
      name:    'detect magic',
      success: ['Ты чувствуешь покалывание в глазах.', 'Ты не можешь чувствовать магию ещё лучше.']
    },
    shield:       {
      name:    'shield',
      success: ['Тебя уже защищает магический щит.', 'Ты окружаешься волшебным силовым щитом.']
    },
    bless: {
      name: 'bless',
      success: ['У тебя уже есть божественное благословение.', 'Ты получаешь благословение от своего Бога.']
    },
    detect_invis: {
      name: 'detect invis',
      success: ['Ты начинаешь видеть невидимое.'  'Ты уже видишь невидимое.']
    },
    invisibility: {
      name: 'invisibility',
      success: ['Ты растворяешься в пространстве.', 'Ты уже невидим.']
    },
    cure_blindness: {
      name: 'cure blindness',
      success: ['Ты и так нормально видишь.']
    },
    refresh: {
      name: 'refresh',
      success: ['Ты совсем не чувствуешь усталости.']
    },
    continual_light: {
      name: 'continual light',
      success: ['Ты делаешь пасс руками - и появляется ярко светящийся шар.']
    },
    remove_splinters: {
      name: 'remove splinters',
      success: ['У тебя нет заноз.']
    },
    detect_poison: {
      name: 'detect poison',
      success: ['Вроде бы яда тут нет.']
    },
    infravision: {
      name: 'infravision',
      success: ['В твоих глазах загорелись красные огоньки.', 'Ты уже видишь в темноте.']
    },
    locate_object: {
      name: 'locate object',
      success: ['Найти что?']
    },
    recharge: {
      name: 'recharge',
      success: ['Эта вещь не перезаряжается.']
    },
    create_food: {
      name: 'create food',
      success: [/^Перед тобой вдруг появляется (.*)/]
    },
    fly: {
      name: 'fly',
      success: ['Ты взлетаешь.', 'Ты уже можешь летать.']
    }
  }

  SKILLS = {
    trip: {
      name:    'trip',
      success: [/Ты подсекаешь (.*), и (.+) падает!/],
      failure: [/^Твоя подсечка промахивается мимо(.*)/, 'Но ты ни с кем не сражаешься!']
    },
    kick: {
      name:    'kick',
      success: [/^Твой удар ногой (.*)/],
      failure: [/^Ты пытаешься пнуть (.*)/, /^Твой удар ногой промахивается (.*)/, 'Но ты ни с кем не сражаешься!']
    },
    bash: {
      name:    'bash',
      success: [/^Ты сбиваешь (.*) с ног, заставляя (.*) ползать!/],
      failure: [/^Тебе не удалось сбить с ног (.*)/, 'Но ты ни с кем не сражаешься!']
    },
    dirt: {
      name: 'dirt',
      success: [/^(.*) ослеплён грязью, попавшей в глаза!$/],
      failure: [/^Твой броcок грязью промахивается (.*)/, 'Но ты не воюешь!']
    }
  }

end

