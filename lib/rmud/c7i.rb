module RMud
  module C7i

    SPELL_FAILURE = 'Ты не смог сосредоточиться.'
    SPELLS = {
      cure_light:       {
        name:    'cure light',
        success: ['Ты уже здоров, как бык.', 'Ты чувствуешь себя слегка лучше!'],
        tags:    [:self]
      },
      cure_serious:     {
        name:    'cure serious',
        success: ['Ты уже здоров, как бык.', 'Ты чувствуешь себя лучше!'],
        tags:    [:self]
      },
      cure_blindness:   {
        name:    'cure blindness',
        success: ['Ты и так нормально видишь.'],
        tags:    [:self]
      },
      cure_disease:     {
        name:    'cure disease',
        success: [/Ты не болеешь/],
        tags:    [:self]
      },

      armor:            {
        name:    'armor',
        success: ['Hа тебе уже есть магическая защита.', 'Ты чувствуешь, как что-то защищает тебя.'],
        tags:    [:self]
      },
      shield:           {
        name:    'shield',
        success: ['Тебя уже защищает магический щит.', 'Ты окружаешься волшебным силовым щитом.'],
        tags:    [:self]
      },
      bless:            {
        name:    'bless',
        success: ['У тебя уже есть божественное благословение.', 'Ты получаешь благословение от своего Бога.'],
        tags:    [:self]
      },
      stone_skin:       {
        name:    'stone skin',
        success: [/Твоя кожа превращается в камень/, /Твоя кожа уже тверда, как камень/],
        tags:    [:self]
      },
      protection_evil:  {
        name:    'protection evil',
        success: [/Ты чувствуешь себя очищенным и благословленным/, /У тебя уже есть защита/],
        tags:    [:self]
      },
      protection_good:  {
        name:    'protection good',
        success: [/Боги Зла не хотят защищать тебя от сил Добра/],
        tags:    [:self]
      },


      giant_strength:   {
        name:    'giant strength',
        success: [/Твои мускулы дрожат от избытка силы!/, /Ты не можешь стать ещё сильнее!/],
        tags:    [:self]
      },
      fly:              {
        name:    'fly',
        success: ['Ты взлетаешь.', 'Ты уже можешь летать.'],
        tags:    [:self]
      },
      invisibility:     {
        name:    'invisibility',
        success: ['Ты растворяешься в пространстве.', 'Ты уже невидим.'],
        tags:    [:self]
      },
      infravision:      {
        name:    'infravision',
        success: ['В твоих глазах загорелись красные огоньки.', 'Ты уже видишь в темноте.'],
        tags:    [:self]
      },


      detect_magic:     {
        name:    'detect magic',
        success: ['Ты чувствуешь покалывание в глазах.', 'Ты не можешь чувствовать магию ещё лучше.'],
        tags:    [:self]
      },
      detect_invis:     {
        name:    'detect invis',
        success: ['Ты начинаешь видеть невидимое.', 'Ты уже видишь невидимое.'],
        tags:    [:self]
      },
      detect_poison:    {
        name:    'detect poison',
        success: ['Вроде бы яда тут нет.'],
        tags:    [:self]
      },
      detect_hidden:    {
        name:    'detect hidden',
        success: [/Ты начинаешь видеть скрытое от невооружённого глаза/, /Ты уже видишь скрытые формы жизни/],
        tags:    [:self]
      },
      detect_alignment: {
        name:    'detect alignment',
        success: [/Ты теперь можешь чувствовать добро и зло/, /Ты уже можешь различать добро и зло/],
        tags:    [:self]
      },
      farsight:         {
        name:    'farsight',
        success: [/Твой взгляд устремляется вдаль/, /Ты хочешь видеть ЕЩЁ дальше/],
        tags:    [:self]
      },


      refresh:          {
        name:    'refresh',
        success: ['Ты совсем не чувствуешь усталости.'],
        tags:    [:self]
      },
      continual_light:  {
        name:    'continual light',
        success: ['Ты делаешь пасс руками - и появляется ярко светящийся шар.'],
        tags:    [:self]
      },
      remove_splinters: {
        name:    'remove splinters',
        success: ['У тебя нет заноз.'],
        tags:    [:self]
      },
      locate_object:    {
        name:    'locate object',
        success: ['Найти что?'],
        tags:    [:self]
      },
      recharge:         {
        name:    'recharge',
        success: ['Эта вещь не перезаряжается.']
      },
      create_food:      {
        name:    'create food',
        success: [/^Перед тобой вдруг появляется (.*)/]
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
        name:    'dirt',
        success: [/^(.*) ослеплён грязью, попавшей в глаза!$/],
        failure: [/^Твой броcок грязью промахивается (.*)/, 'Но ты не воюешь!']
      }
    }

  end
end

