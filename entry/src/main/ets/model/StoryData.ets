import { Choice, CompareOp, Ending, StatKey, StoryNode } from './Types';

/** 整本剧情：11 个节点、5 个结局，节点之间通过 nextId 组成有向图 */
export interface StoryBook {
  startId: string;
  nodes: StoryNode[];
  endings: Ending[];
}

const CLUE: StatKey = StatKey.CLUE;
const TRUST: StatKey = StatKey.TRUST;
const SANITY: StatKey = StatKey.SANITY;

export const NODES: StoryNode[] = [
  {
    id: 'n1',
    chapter: '第一章 · 雾中来信',
    scene: '十六铺码头 · 23:47',
    title: '匿名信',
    speaker: '旁白',
    lines: [
      '民国二十六年冬，上海。雾从黄浦江上漫过来，把十六铺的灯一盏一盏吞掉。',
      '你叫沈砚，《申报》社会版记者。三个小时前，一封没有署名的信被塞进报馆门缝，上面只有一行字：永昌号没有沉。今夜十一点，十六铺三号仓。',
      '三年前，永昌号在吴淞口外沉没，二十七人遇难。案子结了，卷宗封了，只有你还在翻。'
    ],
    choices: [
      {
        id: 'a_read',
        text: '当场拆开信封',
        tag: '线索 +1',
        nextId: 'n2',
        effects: [{ stat: CLUE, delta: 1 }],
        flags: ['letter_read'],
        requires: [],
        lockHint: ''
      },
      {
        id: 'a_watch',
        text: '先绕到栈桥后面，看看有没有人跟着',
        tag: '理智 +1 · 线索 +1',
        nextId: 'n2',
        effects: [{ stat: SANITY, delta: 1 }, { stat: CLUE, delta: 1 }],
        flags: [],
        requires: [],
        lockHint: ''
      },
      {
        id: 'a_leave',
        text: '把信塞回大衣口袋，今晚不去了',
        tag: '理智 +1',
        nextId: 'n2',
        effects: [{ stat: SANITY, delta: 1 }],
        flags: ['hesitated'],
        requires: [],
        lockHint: ''
      }
    ],
    endingId: ''
  },
  {
    id: 'n2',
    chapter: '第一章 · 雾中来信',
    scene: '三号仓门外 · 23:58',
    title: '工头阿四',
    speaker: '阿四',
    lines: [
      '三号仓的铁门只开了一条缝，缝里露出一只眼睛，和半截烧到指根的烟。',
      '"记者？"阿四把烟头摁在门框上，"三年前也有个记者来问过永昌号。后来他就不来了。"',
      '他侧过身，让你看见仓库深处码得整整齐齐的木箱。'
    ],
    choices: [
      {
        id: 'b_card',
        text: '亮出记者证，直接问他永昌号',
        tag: '线索 +1 · 信任 -1',
        nextId: 'n3',
        effects: [{ stat: CLUE, delta: 1 }, { stat: TRUST, delta: -1 }],
        flags: [],
        requires: [],
        lockHint: ''
      },
      {
        id: 'b_smoke',
        text: '递一支烟，先聊码头上的旧事',
        tag: '线索 +1 · 理智 +1',
        nextId: 'n3',
        effects: [{ stat: CLUE, delta: 1 }, { stat: SANITY, delta: 1 }],
        flags: [],
        requires: [],
        lockHint: ''
      },
      {
        id: 'b_direct',
        text: '盯着他问：那晚，你在不在船上',
        tag: '线索 +2 · 信任 -1',
        nextId: 'n3',
        effects: [{ stat: CLUE, delta: 2 }, { stat: TRUST, delta: -1 }],
        flags: [],
        requires: [{ stat: CLUE, op: CompareOp.GTE, value: 2 }],
        lockHint: '需要 线索 ≥ 2'
      }
    ],
    endingId: ''
  },
  {
    id: 'n3',
    chapter: '第一章 · 雾中来信',
    scene: '三号仓内 · 00:12',
    title: '刻着「永昌」的木箱',
    speaker: '旁白',
    lines: [
      '木箱的封条是新的，箱角却刻着两个字：永昌。你撬开其中一只，里面是油布包着的步枪，枪油味冲得人眼睛发酸。',
      '阿四在你身后轻轻说："这批货，今晚还要上船。"',
      '仓库外传来汽车熄火的声音。有人来了。'
    ],
    choices: [
      {
        id: 'c_photo',
        text: '举起相机，拍下箱号和封条',
        tag: '线索 +2 · 理智 -1',
        nextId: 'n4',
        effects: [{ stat: CLUE, delta: 2 }, { stat: SANITY, delta: -1 }],
        flags: ['photo'],
        requires: [{ stat: CLUE, op: CompareOp.GTE, value: 2 }],
        lockHint: '需要 线索 ≥ 2'
      },
      {
        id: 'c_copy',
        text: '用铅笔把编号抄在手心',
        tag: '线索 +1',
        nextId: 'n4',
        effects: [{ stat: CLUE, delta: 1 }],
        flags: [],
        requires: [],
        lockHint: ''
      },
      {
        id: 'c_out',
        text: '什么都不碰，原路退出去',
        tag: '理智 +1',
        nextId: 'n4',
        effects: [{ stat: SANITY, delta: 1 }],
        flags: [],
        requires: [],
        lockHint: ''
      }
    ],
    endingId: ''
  },
  {
    id: 'n4',
    chapter: '第二章 · 旧账',
    scene: '申报馆 档案室 · 01:20',
    title: '二十七个人',
    speaker: '旁白',
    lines: [
      '档案室的灯管嗡嗡响。三年前的旧报堆到天花板，永昌号的消息只占了豆腐块大小的一块版面：沉没，二十七人遇难，原因不明，结案。',
      '你把遇难者名单抄在稿纸上，忽然发现一个不对的地方——名单里的第二十七个人，没有年龄。',
      '没有年龄，通常意味着，这个人根本不该出现在名单上。'
    ],
    choices: [
      {
        id: 'd_film',
        text: '调出三年前的微缩胶片，一版一版看',
        tag: '线索 +1 · 理智 -1',
        nextId: 'n5',
        effects: [{ stat: CLUE, delta: 1 }, { stat: SANITY, delta: -1 }],
        flags: [],
        requires: [],
        lockHint: ''
      },
      {
        id: 'd_editor',
        text: '去排字房，问值夜的老编辑',
        tag: '线索 +1 · 理智 +1',
        nextId: 'n5',
        effects: [{ stat: CLUE, delta: 1 }, { stat: SANITY, delta: 1 }],
        flags: [],
        requires: [],
        lockHint: ''
      },
      {
        id: 'd_cross',
        text: '把遇难者名单和船员名册逐行对照',
        tag: '线索 +2',
        nextId: 'n5',
        effects: [{ stat: CLUE, delta: 2 }],
        flags: ['name_mismatch'],
        requires: [{ stat: CLUE, op: CompareOp.GTE, value: 3 }],
        lockHint: '需要 线索 ≥ 3'
      }
    ],
    endingId: ''
  },
  {
    id: 'n5',
    chapter: '第二章 · 旧账',
    scene: '巡捕房 后门 · 02:05',
    title: '探长顾长风',
    speaker: '顾长风',
    lines: [
      '顾长风站在后门的雨里，没穿制服，手里拎着两只还冒热气的生煎。',
      '"沈砚，"他把其中一只递给你，"三年前那个记者，死的时候手里也攥着一封信。"',
      '他顿了顿："我劝你，别再往下看了。"'
    ],
    choices: [
      {
        id: 'e_tell',
        text: '把这几天查到的一切都告诉他',
        tag: '信任 +2 · 线索 +1',
        nextId: 'n6',
        effects: [{ stat: TRUST, delta: 2 }, { stat: CLUE, delta: 1 }],
        flags: ['told_gu'],
        requires: [],
        lockHint: ''
      },
      {
        id: 'e_hide',
        text: '只提匿名信，其余一个字不说',
        tag: '信任 -1 · 理智 +1',
        nextId: 'n6',
        effects: [{ stat: TRUST, delta: -1 }, { stat: SANITY, delta: 1 }],
        flags: [],
        requires: [],
        lockHint: ''
      },
      {
        id: 'e_probe',
        text: '反问他：这案子当年为什么结得那么快',
        tag: '线索 +1 · 信任 -1',
        nextId: 'n6',
        effects: [{ stat: CLUE, delta: 1 }, { stat: TRUST, delta: -1 }],
        flags: ['gu_doubt'],
        requires: [{ stat: CLUE, op: CompareOp.GTE, value: 4 }],
        lockHint: '需要 线索 ≥ 4'
      }
    ],
    endingId: ''
  },
  {
    id: 'n6',
    chapter: '第二章 · 旧账',
    scene: '百乐门 二楼 · 22:10',
    title: '歌女白露',
    speaker: '白露',
    lines: [
      '白露唱完最后一支曲子，在后台卸耳环。镜子里的人比台上老了十岁。',
      '"永昌号？"她的手停了一下，"那晚我在船上。二十七个人里，本该有第二十八个。"',
      '她把耳环摘下来，放在掌心："你要听，就先告诉我，你打算拿它做什么。"'
    ],
    choices: [
      {
        id: 'f_song',
        text: '请乐队再奏一支她当年在船上唱过的曲子',
        tag: '线索 +1 · 信任 +1',
        nextId: 'n7',
        effects: [{ stat: CLUE, delta: 1 }, { stat: TRUST, delta: 1 }],
        flags: [],
        requires: [],
        lockHint: ''
      },
      {
        id: 'f_money',
        text: '把钞票压在杯底，请她换个地方说话',
        tag: '线索 +1 · 理智 -1',
        nextId: 'n7',
        effects: [{ stat: CLUE, delta: 1 }, { stat: SANITY, delta: -1 }],
        flags: [],
        requires: [],
        lockHint: ''
      },
      {
        id: 'f_ask',
        text: '直接问她：那晚你在船上，看见了什么',
        tag: '线索 +2 · 信任 -1',
        nextId: 'n7',
        effects: [{ stat: CLUE, delta: 2 }, { stat: TRUST, delta: -1 }],
        flags: ['bailu_truth'],
        requires: [{ stat: CLUE, op: CompareOp.GTE, value: 4 }],
        lockHint: '需要 线索 ≥ 4'
      }
    ],
    endingId: ''
  },
  {
    id: 'n7',
    chapter: '第二章 · 旧账',
    scene: '百乐门 后巷 · 23:30',
    title: '海隼号',
    speaker: '白露',
    lines: [
      '后巷的雾更浓。白露把一张折成四折的货单塞进你手里。',
      '"海隼号，今晚离港。货单上写的是机器零件。"她笑了一下，"二十七个人的命，在他们账上就是四个字：机器零件。"',
      '远处传来巡捕房的哨声。她转身走进雾里，高跟鞋的声音一下一下，很快听不见了。'
    ],
    choices: [
      {
        id: 'g_dock',
        text: '立刻去码头',
        tag: '理智 -1',
        nextId: 'n8',
        effects: [{ stat: SANITY, delta: -1 }],
        flags: [],
        requires: [],
        lockHint: ''
      },
      {
        id: 'g_press',
        text: '先回报馆，把稿子发出去',
        tag: '线索 +1',
        nextId: 'n8',
        effects: [{ stat: CLUE, delta: 1 }],
        flags: ['published'],
        requires: [],
        lockHint: ''
      },
      {
        id: 'g_gu',
        text: '去找顾长风，把话摊开说',
        tag: '信任 +2',
        nextId: 'n8',
        effects: [{ stat: TRUST, delta: 2 }],
        flags: ['gu_ally'],
        requires: [{ stat: TRUST, op: CompareOp.GTE, value: 3 }],
        lockHint: '需要 信任 ≥ 3'
      }
    ],
    endingId: ''
  },
  {
    id: 'n8',
    chapter: '第三章 · 沉船',
    scene: '海隼号 货舱 · 00:40',
    title: '账本',
    speaker: '旁白',
    lines: [
      '海隼号的货舱里没有机器零件。木箱上的编号，和你手心里抄的一模一样。',
      '舱角有一只铁皮柜，没锁。里面是一本账，密密麻麻记着日期、船号、数目，还有几个你认得的名字。',
      '身后的铁梯响了。有人下来了。'
    ],
    choices: [
      {
        id: 'h_hide',
        text: '闪身躲进集装箱的夹缝',
        tag: '线索 +1 · 理智 -1',
        nextId: 'n9',
        effects: [{ stat: CLUE, delta: 1 }, { stat: SANITY, delta: -1 }],
        flags: ['ledger'],
        requires: [],
        lockHint: ''
      },
      {
        id: 'h_flash',
        text: '举起相机，对着来人按下快门',
        tag: '线索 +1 · 理智 -1',
        nextId: 'n9',
        effects: [{ stat: CLUE, delta: 1 }, { stat: SANITY, delta: -1 }],
        flags: ['ledger', 'photo_man'],
        requires: [],
        lockHint: ''
      },
      {
        id: 'h_grab',
        text: '抓起账本就跑',
        tag: '线索 +2 · 理智 -2',
        nextId: 'n9',
        effects: [{ stat: CLUE, delta: 2 }, { stat: SANITY, delta: -2 }],
        flags: ['ledger'],
        requires: [{ stat: SANITY, op: CompareOp.GTE, value: 4 }],
        lockHint: '需要 理智 ≥ 4'
      }
    ],
    endingId: ''
  },
  {
    id: 'n9',
    chapter: '第三章 · 沉船',
    scene: '海隼号 货舱 · 00:52',
    title: '他也在这条船上',
    speaker: '顾长风',
    lines: [
      '下来的不是别人。顾长风举着手电，光柱在账本上停了很久。',
      '"三年前我就该上这条船。"他说，"可我得先活着，才能把名单带出去。"',
      '他把手电往下一压："现在，你打算怎么办？"'
    ],
    choices: [
      {
        id: 'i_give',
        text: '把账本交给他',
        tag: '信任 +2 · 线索 +1',
        nextId: 'n10',
        effects: [{ stat: TRUST, delta: 2 }, { stat: CLUE, delta: 1 }],
        flags: ['trust_gu'],
        requires: [],
        lockHint: ''
      },
      {
        id: 'i_confront',
        text: '质问他：你早就知道，是不是',
        tag: '信任 -1 · 线索 +1',
        nextId: 'n10',
        effects: [{ stat: TRUST, delta: -1 }, { stat: CLUE, delta: 1 }],
        flags: [],
        requires: [],
        lockHint: ''
      },
      {
        id: 'i_keep',
        text: '把账本塞进怀里，谁也不给',
        tag: '线索 +2 · 信任 -2 · 理智 -1',
        nextId: 'n10',
        effects: [{ stat: CLUE, delta: 2 }, { stat: TRUST, delta: -2 }, { stat: SANITY, delta: -1 }],
        flags: ['alone'],
        requires: [],
        lockHint: ''
      }
    ],
    endingId: ''
  },
  {
    id: 'n10',
    chapter: '第三章 · 沉船',
    scene: '海隼号 甲板 · 01:15',
    title: '火光',
    speaker: '旁白',
    lines: [
      '货舱先烧起来的。有人在下面浇了煤油，火沿着铁梯往上爬，把雾照成一片橘红。',
      '岸上的警笛越来越近。顾长风把账本护在怀里，回头看你。',
      '你还有最后一次选择。'
    ],
    choices: [
      {
        id: 'j_jump',
        text: '翻过栏杆，跳进江里',
        tag: '理智 -1',
        nextId: 'n11',
        effects: [{ stat: SANITY, delta: -1 }],
        flags: ['jump'],
        requires: [],
        lockHint: ''
      },
      {
        id: 'j_bait',
        text: '把账本扔给顾长风，自己去引开追兵',
        tag: '信任 +2 · 理智 -1',
        nextId: 'n11',
        effects: [{ stat: TRUST, delta: 2 }, { stat: SANITY, delta: -1 }],
        flags: ['sacrifice'],
        requires: [],
        lockHint: ''
      },
      {
        id: 'j_save',
        text: '回头去舱里救白露',
        tag: '理智 -2 · 信任 +1',
        nextId: 'n11',
        effects: [{ stat: SANITY, delta: -2 }, { stat: TRUST, delta: 1 }],
        flags: ['saved_bailu'],
        requires: [{ stat: SANITY, op: CompareOp.GTE, value: 4 }],
        lockHint: '需要 理智 ≥ 4'
      }
    ],
    endingId: ''
  },
  {
    id: 'n11',
    chapter: '终章',
    scene: '黄浦江 · 01:40',
    title: '雾还没有散',
    speaker: '旁白',
    lines: [
      '天快亮的时候，火小了。雾却更浓。',
      '你把大衣裹紧，听见江面上有船在鸣笛，一声长，一声短，像是在跟谁告别。'
    ],
    choices: [],
    endingId: 'resolve'
  }
];

export const ENDINGS: Ending[] = [
  {
    id: 'e_true',
    title: '雾散',
    rank: 'S',
    caption: '真相浮出水面',
    description: '账本上的名字一个接一个被登出来。海隼号没能出港，永昌号的二十七个人，终于有了一个说得清的死因。顾长风调去了别处，临走前把那半包生煎放在你桌上。'
  },
  {
    id: 'e_ash',
    title: '余烬',
    rank: 'A',
    caption: '真相只烧剩半页',
    description: '你带出了账本，可它能登出来的只剩半页。剩下的部分，被一场更大的火、或者更大的手，按了下去。你还在写，只是不再确定有没有人读。'
  },
  {
    id: 'e_deal',
    title: '共谋',
    rank: 'B',
    caption: '你成了账本上的一行',
    description: '第二天，报馆收到一笔来路不明的广告费，数目刚好够你三年的薪水。你把账本锁进抽屉，钥匙扔进了黄浦江。雾散那天，你发现自己也学会了对人笑。'
  },
  {
    id: 'e_leave',
    title: '离岸',
    rank: 'C',
    caption: '你离开了上海',
    description: '你搭上早班船离开上海。船过吴淞口的时候，你把那封信撕碎，撒进江里。有些真相留在雾里，比带出来更安全——你这样告诉自己，很多年。'
  },
  {
    id: 'e_lost',
    title: '失踪者',
    rank: 'C',
    caption: '第二十八个人',
    description: '你开始分不清雾里的脚步声是自己的，还是别人的。三天后，报馆在你的桌上发现一沓没写完的稿纸，最后一页只有半句话：名单上的第二十八个人，是……'
  }
];

export const STORY: StoryBook = {
  startId: 'n1',
  nodes: NODES,
  endings: ENDINGS
};

export function findNode(id: string): StoryNode | null {
  for (let i = 0; i < NODES.length; i++) {
    if (NODES[i].id === id) {
      return NODES[i];
    }
  }
  return null;
}

export function findEnding(id: string): Ending | null {
  for (let i = 0; i < ENDINGS.length; i++) {
    if (ENDINGS[i].id === id) {
      return ENDINGS[i];
    }
  }
  return null;
}
