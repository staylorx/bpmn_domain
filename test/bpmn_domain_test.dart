import 'package:bpmn_domain/bpmn_domain.dart';
import 'package:shouldly/shouldly.dart';
import 'package:test/test.dart';

void main() {
  // =========================================================================
  // Value objects
  // =========================================================================

  group('Given NodeId', () {
    test('Then equality is structural', () {
      const NodeId('ProcessOrder').should.be(const NodeId('ProcessOrder'));
      const NodeId('ProcessOrder').should.not.be(const NodeId('Other'));
    });

    test('Then isSimpleName rejects qualified names', () {
      const NodeId('ProcessOrder').isSimpleName.should.beTrue();
      const NodeId('de.monticore.bpmn').isSimpleName.should.beFalse();
    });

    test('Then toString returns value', () {
      (const NodeId('Foo').toString()).should.be('Foo');
    });
  });

  group('Given QualifiedNodeId', () {
    test('Then parse splits on dots', () {
      final q = QualifiedNodeId.parse(
        dotSeparated: 'de.monticore.bpmn.examples.OrderToDeliveryWorkflow',
      );
      q.segments.should.haveCount(5);
      (q.simpleName).should.be('OrderToDeliveryWorkflow');
      (q.qualifier).should.be('de.monticore.bpmn.examples');
    });

    test('Then toString rejoins segments', () {
      final q = QualifiedNodeId(segments: ['de', 'pkg', 'MyProcess']);
      (q.toString()).should.be('de.pkg.MyProcess');
    });
  });

  group('Given PackagePath', () {
    test('Then root is empty', () {
      PackagePath.root.isRoot.should.beTrue();
      (PackagePath.root.toString()).should.be('');
    });

    test('Then parse produces correct segments', () {
      final p = PackagePath.parse(dotSeparated: 'de.monticore.bpmn.examples');
      (p.segments).should.be(['de', 'monticore', 'bpmn', 'examples']);
    });

    test('Then qualify prepends package', () {
      final p = PackagePath.parse(dotSeparated: 'de.monticore.bpmn.examples');
      p
          .qualify('OrderToDeliveryWorkflow')
          .should
          .be('de.monticore.bpmn.examples.OrderToDeliveryWorkflow');
    });

    test('Then root qualify returns simple name', () {
      (PackagePath.root.qualify('Simple')).should.be('Simple');
    });
  });

  group('Given Stereotype', () {
    test('Then incarnates factory', () {
      final s = Stereotype.incarnates(referenceName: 'Research');
      (s.key).should.be('incarnates');
      (s.value).should.be('Research');
      (s.toString()).should.be('<<incarnates="Research">>');
    });

    test('Then marker stereotype without value', () {
      const s = Stereotype(key: 'abstract');
      (s.toString()).should.be('<<abstract>>');
    });
  });

  group('Given WfModifier', () {
    test('Then none has no stereotypes', () {
      WfModifier.none.stereotypes.should.beEmpty();
      WfModifier.none.isIncarnation.should.beFalse();
    });

    test('Then incarnatesTarget is extracted correctly', () {
      final mod = WfModifier(
        stereotypes: [Stereotype.incarnates(referenceName: 'Draft')],
      );
      mod.isIncarnation.should.beTrue();
      (mod.incarnatesTarget).should.be('Draft');
    });
  });

  group('Given WfTypeRef', () {
    test('Then equality is structural', () {
      WfTypeRef.string.should.be(const WfTypeRef(expression: 'String'));
      WfTypeRef.named(name: 'Order').should.be(WfTypeRef.named(name: 'Order'));
    });
  });

  group('Given ImportStatement', () {
    test('Then wildcard toString', () {
      const imp = ImportStatement(
        path: 'de.monticore.bpmn.cds.OrderToDelivery',
        wildcard: true,
      );
      (imp.toString()).should.be(
        'import de.monticore.bpmn.cds.OrderToDelivery.*;',
      );
    });

    test('Then named import toString', () {
      const imp = ImportStatement(
        path: 'de.monticore.bpmn.cds.OrderToDelivery.Order',
      );
      imp.toString().should.be(
        'import de.monticore.bpmn.cds.OrderToDelivery.Order;',
      );
    });
  });

  // =========================================================================
  // Gateway entities
  // =========================================================================

  group('Given WfGateway', () {
    test('Then splitXor factory', () {
      final g = WfGateway.splitXor(name: 'OrderFulfillable');
      (g.id).should.be(const NodeId('OrderFulfillable'));
      (g.direction).should.be(GatewayDirection.split);
      g.kind.should.beOfType<ExclusiveGateway>();
    });

    test('Then mergeAnd factory', () {
      final g = WfGateway.mergeAnd(name: 'MergeWork');
      (g.direction).should.be(GatewayDirection.merge);
      g.kind.should.beOfType<ParallelGateway>();
    });

    test('Then splitReceiveFirst is event-based', () {
      final g = WfGateway.splitReceiveFirst(name: 'WaitForResponse');
      g.kind.should.beOfType<ExclusiveEventGateway>();
    });

    test('Then complex gateway carries guard expression', () {
      final g = const WfGateway(
        id: NodeId('VoteDecision'),
        direction: GatewayDirection.split,
        kind: ComplexGateway(guard: 'majority(votes) > 0.5'),
      );
      ((g.kind as ComplexGateway).guard).should.be('majority(votes) > 0.5');
    });

    test('Then equality is structural', () {
      final a = WfGateway.splitXor(name: 'G');
      final b = WfGateway.splitXor(name: 'G');
      a.should.be(b);
    });
  });

  group('Given WfInlineGateway', () {
    test('Then inline gateway has no id', () {
      const gw = WfInlineGateway(
        direction: GatewayDirection.split,
        kind: ExclusiveGateway(),
      );
      (gw.direction).should.be(GatewayDirection.split);
    });
  });

  // =========================================================================
  // Event trigger entities
  // =========================================================================

  group('Given EventTrigger', () {
    test('Then CancelTrigger toString', () {
      (const CancelTrigger().toString()).should.be('cancel');
    });

    test('Then CompensateTrigger with activity', () {
      final t = const CompensateTrigger(activity: NodeId('ProcessOrder'));
      (t.toString()).should.be('compensate ProcessOrder');
    });

    test('Then CompensateTrigger async flag', () {
      const t = CompensateTrigger(async: true);
      (t.toString()).should.be('compensate async');
    });

    test('Then ConditionalTrigger', () {
      const t = ConditionalTrigger(condition: 'stock.available > 0');
      (t.toString()).should.be('when [stock.available > 0]');
    });

    test('Then TerminateTrigger', () {
      (const TerminateTrigger().toString()).should.be('terminate');
    });

    test('Then TimerTrigger', () {
      const t = TimerTrigger(condition: 'after PT4H');
      (t.toString()).should.be('timer [after PT4H]');
    });

    test('Then NotificationTrigger message', () {
      final t = const NotificationTrigger(
        kind: NotificationKind.message,
        notificationName: NodeId('cancelMsg'),
      );
      (t.toString()).should.be('message cancelMsg');
    });

    test('Then MultipleTrigger one', () {
      final t = const MultipleTrigger(
        triggers: [CancelTrigger(), TerminateTrigger()],
        parallel: false,
      );
      (t.toString()).should.be('one { cancel, terminate }');
    });

    test('Then MultipleTrigger all is parallel', () {
      final t = const MultipleTrigger(
        triggers: [CancelTrigger()],
        parallel: true,
      );
      (t.toString()).should.be('all { cancel }');
    });
  });

  // =========================================================================
  // WfEvent entity
  // =========================================================================

  group('Given WfEvent', () {
    test('Then start factory creates catching start', () {
      final e = WfEvent.start(name: 'ReceiveOrder');
      (e.id).should.be(const NodeId('ReceiveOrder'));
      (e.role).should.be(EventRole.start);
      (e.direction).should.be(EventDirection.catch_);
      e.isStart.should.beTrue();
      e.isNoneEvent.should.beTrue();
    });

    test('Then end factory creates throwing end', () {
      final e = WfEvent.end(name: 'OrderCompleted');
      (e.role).should.be(EventRole.end);
      (e.direction).should.be(EventDirection.throw_);
      e.isEnd.should.beTrue();
    });

    test('Then terminate end event', () {
      final e = WfEvent.terminate(name: 'ProcessAborted');
      e.trigger.should.beOfType<TerminateTrigger>();
    });

    test('Then timerCatch event', () {
      final e = WfEvent.timerCatch('DailyReminder', 'every P1D');
      e.isTimer.should.beTrue();
      (e.direction).should.be(EventDirection.catch_);
      ((e.trigger as TimerTrigger).condition).should.be('every P1D');
    });

    test('Then compensationBoundary event', () {
      final e = WfEvent.compensationBoundary(
        name: 'PossibleCancellation',
        compensatedActivity: 'ProcessOrder',
        handlerActivity: 'RollbackOrderProcessing',
      );
      e.isBoundary.should.beTrue();
      (e.compensationHandler?.compensatedActivity.value).should.be(
        'ProcessOrder',
      );
      (e.compensationHandler?.handlerActivity.value).should.be(
        'RollbackOrderProcessing',
      );
    });

    test('Then messageCatchStart', () {
      final e = WfEvent.messageCatchStart('ReceiveOrder', 'orderMsg');
      e.isMessage.should.beTrue();
      e.isStart.should.beTrue();
    });

    test('Then errorEnd', () {
      final e = WfEvent.errorEnd('PaymentFailed', 'CardDeclinedError');
      e.isEnd.should.beTrue();
      final trigger = e.trigger as NotificationTrigger;
      (trigger.kind).should.be(NotificationKind.error);
    });
  });

  // =========================================================================
  // Activity entities
  // =========================================================================

  group('Given LoopCharacteristic', () {
    test('Then WfStandardLoop while', () {
      final l = WfStandardLoop.whileLoop(condition: 'retries < 3', max: 5);
      l.isWhile.should.beTrue();
      (l.loopCondition).should.be('retries < 3');
      (l.maxIterations).should.be(5);
      (l.toString()).should.be('while [retries < 3] max 5');
    });

    test('Then WfStandardLoop until', () {
      final l = WfStandardLoop.untilLoop(condition: 'delivered == true');
      l.isWhile.should.beFalse();
      (l.toString()).should.be('until [delivered == true]');
    });

    test('Then WfLoopCardinality literal', () {
      final c = WfLoopCardinality.count(n: 5);
      (c.literalCount).should.be(5);
      (c.toString()).should.be('count 5');
    });

    test('Then WfLoopCardinality expression', () {
      final c = WfLoopCardinality.expression(
        expr: 'order.numberOfOrderedProducts',
      );
      (c.expression).should.be('order.numberOfOrderedProducts');
      (c.toString()).should.be('count [order.numberOfOrderedProducts]');
    });

    test('Then WfLoopCardinality collection', () {
      final c = WfLoopCardinality.collection(name: 'orderItems');
      (c.collectionName).should.be('orderItems');
      (c.toString()).should.be('count orderItems');
    });

    test('Then WfMILoop parallel over collection', () {
      final l = WfMILoop.parallelOver(collectionName: 'orderItems');
      l.isParallel.should.beTrue();
      (l.cardinality.collectionName).should.be('orderItems');
    });

    test('Then WfMILoop sequential', () {
      final l = WfMILoop.sequential(count: 3);
      l.isParallel.should.beFalse();
      (l.cardinality.literalCount).should.be(3);
    });
  });

  group('Given WfTask', () {
    test('Then generic task factory', () {
      final t = WfTask.generic(name: 'Introduction');
      (t.id.value).should.be('Introduction');
      (t.type).should.be(TaskType.generic);
      t.hasBoundaryEvents.should.beFalse();
    });

    test('Then service task factory', () {
      final t = WfTask.service(
        name: 'ProcessOrder',
        webservice: '##webservice',
        operationName: 'processOrderOp',
      );
      (t.type).should.be(TaskType.service);
      (t.taskTypeAttributes?.webservice).should.be('##webservice');
      (t.taskTypeAttributes?.operation?.value).should.be('processOrderOp');
    });

    test('Then manual task with resources', () {
      final t = WfTask.manual('PrepareAndPackProducts', ['order', 'products']);
      (t.type).should.be(TaskType.manual);
      (t.taskTypeAttributes?.resources).should.be(['order', 'products']);
    });

    test('Then send task', () {
      final t = WfTask.send(
        name: 'SendCancellationMessage',
        webservice: '##webservice',
        messageName: 'cancelMsg',
        operationName: 'prepCancelMsg',
      );
      (t.type).should.be(TaskType.send);
      (t.taskTypeAttributes?.message?.value).should.be('cancelMsg');
    });

    test('Then script task', () {
      final t = WfTask.script(
        name: 'TransformData',
        format: 'JavaScript',
        body: 'return input.trim();',
      );
      (t.type).should.be(TaskType.script);
      (t.taskTypeAttributes?.scriptFormat).should.be('JavaScript');
    });

    test('Then incarnated task', () {
      final t = WfTask(
        id: const NodeId('LiteratureReview'),
        modifier: WfModifier(
          stereotypes: [Stereotype.incarnates(referenceName: 'Research')],
        ),
      );
      t.isIncarnation.should.beTrue();
      (t.incarnatesTarget).should.be('Research');
    });

    test('Then service task with MI loop', () {
      final t = WfTask.service(
        name: 'CheckProductAvailability',
        webservice: '##webservice',
        loop: WfMILoop(
          cardinality: WfLoopCardinality.expression(
            expr: 'order.numberOfOrderedProducts',
          ),
          isParallel: true,
        ),
      );
      t.loop.should.beOfType<WfMILoop>();
    });
  });

  group('Given WfSubProcess', () {
    test('Then embedded subprocess', () {
      final sp = WfSubProcess.embedded(name: 'ShipOrder');
      (sp.subProcessType).should.be(SubProcessType.embedded);
      sp.isTransaction.should.beFalse();
    });

    test('Then transaction subprocess', () {
      final sp = WfSubProcess.transaction(name: 'PaymentBlock');
      sp.isTransaction.should.beTrue();
    });

    test('Then adhoc subprocess', () {
      final sp = WfSubProcess.adhoc(
        name: 'PeerReview',
        completionCondition: 'allReviewed',
        parallel: true,
      );
      sp.isAdHoc.should.beTrue();
      sp.adHocCharacteristics?.isParallel.should.beTrue();
      (sp.adHocCharacteristics?.completionCondition).should.be('allReviewed');
    });
  });

  group('Given WfCallActivity', () {
    test('Then simple call activity', () {
      final ca = WfCallActivity.simple(
        name: 'RunDiagnostics',
        calledProcessName: 'DiagnosticsProcess',
      );
      (ca.id.value).should.be('RunDiagnostics');
      (ca.calledElement.value).should.be('DiagnosticsProcess');
    });
  });

  // =========================================================================
  // Data entities
  // =========================================================================

  group('Given WfIORequirement', () {
    test('Then WfIOSet input', () {
      final s = WfIOSet.inputItem('order', WfTypeRef.named(name: 'Order'));
      s.isInput.should.beTrue();
      (s.dataSet.items.first.name.value).should.be('order');
      (s.dataSet.items.first.type?.expression).should.be('Order');
    });

    test('Then WfIOSet output', () {
      final s = WfIOSet.outputItem('report', WfTypeRef.named(name: 'PDF'));
      s.isInput.should.beFalse();
    });

    test('Then WfIORule', () {
      final rule = WfIORule(
        inputSet: WfDataSet.single(
          item: WfDataIO(
            name: const NodeId('order'),
            type: WfTypeRef.named(name: 'Order'),
          ),
        ),
        outputSet: WfDataSet.single(
          item: const WfDataIO(name: NodeId('invoice')),
        ),
      );
      (rule.inputSet.items.first.name.value).should.be('order');
      (rule.outputSet.items.first.name.value).should.be('invoice');
    });

    test('Then WfDataIO loop flag', () {
      final d = WfDataIO(
        name: const NodeId('items'),
        type: WfTypeRef.named(name: 'Product'),
        loop: true,
      );
      d.loop.should.beTrue();
    });

    test('Then WfDataIO optional and whileExecuting', () {
      final d = const WfDataIO(
        name: NodeId('config'),
        optional: true,
        whileExecuting: true,
      );
      d.optional.should.beTrue();
      d.whileExecuting.should.beTrue();
    });
  });

  group('Given WfDataObject', () {
    test('Then data factory', () {
      final d = WfDataObject.data('order', 'Order');
      (d.kind).should.be(DataKind.dataObject);
      d.isDataObject.should.beTrue();
      d.isDataStore.should.beFalse();
      (d.type.expression).should.be('Order');
    });

    test('Then store factory', () {
      final d = WfDataObject.store('products', 'Product');
      (d.kind).should.be(DataKind.dataStore);
      d.isDataStore.should.beTrue();
    });
  });

  group('Given WfNotification', () {
    test('Then message notification', () {
      final n = WfNotification.message('cancelMsg', WfTypeRef.string);
      (n.kind).should.be(NotificationKind.message);
      n.isMessage.should.beTrue();
      (n.type).should.be(WfTypeRef.string);
    });

    test('Then error notification', () {
      final n = WfNotification.error(
        'CardDeclinedError',
        WfTypeRef.named(name: 'CardError'),
      );
      n.isError.should.beTrue();
    });

    test('Then signal notification', () {
      final n = WfNotification.signal(
        'IncidentResolved',
        WfTypeRef.named(name: 'String'),
      );
      n.isSignal.should.beTrue();
    });

    test('Then escalation notification', () {
      final n = WfNotification.escalation(
        'SLAWarning',
        WfTypeRef.named(name: 'SLAViolation'),
      );
      n.isEscalation.should.beTrue();
    });
  });

  group('Given WfOperation', () {
    test('Then request-response operation', () {
      final op = WfOperation.requestResponse(
        name: 'getAddress',
        input: 'customerID',
        output: 'address',
      );
      op.hasOutput.should.beTrue();
      (op.outParam?.value).should.be('address');
    });

    test('Then one-way operation', () {
      final op = WfOperation.oneWay(name: 'sendAlert', input: 'alertMsg');
      op.hasOutput.should.beFalse();
      op.canThrowErrors.should.beFalse();
    });

    test('Then operation with thrown errors', () {
      final op = const WfOperation(
        id: NodeId('authorisePayment'),
        inParam: NodeId('paymentRequest'),
        outParam: NodeId('captureConfirmation'),
        thrownErrors: [NodeId('CardDeclinedError')],
      );
      op.canThrowErrors.should.beTrue();
      (op.thrownErrors.first.value).should.be('CardDeclinedError');
    });
  });

  // =========================================================================
  // Sequence flow entities
  // =========================================================================

  group('Given FlowCondition', () {
    test('Then ExpressionCondition toString', () {
      const c = ExpressionCondition(expression: 'checker.allProductsAvailable');
      (c.toString()).should.be('[checker.allProductsAvailable]');
    });

    test('Then DefaultCondition toString', () {
      (const DefaultCondition().toString()).should.be('[_]');
    });
  });

  group('Given FlowTarget', () {
    test('Then element target', () {
      final t = FlowTarget.element(const NodeId('ProcessOrder'));
      t.isElementRef.should.beTrue();
      t.isGateway.should.beFalse();
      t.isBlock.should.beFalse();
      t.hasCondition.should.beFalse();
    });

    test('Then element target with condition', () {
      final t = FlowTarget.element(
        const NodeId('PrepareAndPackProducts'),
        condition: const ExpressionCondition(
          expression: 'checker.allProductsAvailable',
        ),
      );
      t.hasCondition.should.beTrue();
    });

    test('Then gateway target', () {
      final t = FlowTarget.gateway(
        gw: const WfInlineGateway(
          direction: GatewayDirection.split,
          kind: ExclusiveGateway(),
        ),
      );
      t.isGateway.should.beTrue();
    });

    test('Then block target', () {
      final t = FlowTarget.block(blk: const FlowBlock(branches: []));
      t.isBlock.should.beTrue();
    });
  });

  group('Given SequenceFlow', () {
    test('Then linear flow factory', () {
      final f = SequenceFlow.linear('flow1', [
        'Start',
        'Research',
        'Draft',
        'Done',
      ]);
      f.path.should.haveCount(4);
      (f.path.first.elementRef?.value).should.be('Start');
      (f.path.last.elementRef?.value).should.be('Done');
    });
  });

  // =========================================================================
  // Timer conditions
  // =========================================================================

  group('Given TimerCondition', () {
    test('Then AtTimerCondition toString', () {
      const c = AtTimerCondition(time: TimeOfDay(hours: 9, minutes: 0));
      (c.toString()).should.be('at 09:00');
    });

    test('Then OnDateTimerCondition toString', () {
      const c = OnDateTimerCondition(
        date: CalendarDate(year: 2026, month: 6, day: 30),
      );
      (c.toString()).should.be('on 2026-06-30');
    });

    test('Then OnDateTimerCondition with time', () {
      const c = OnDateTimerCondition(
        date: CalendarDate(year: 2026, month: 6, day: 30),
        atTime: AtTimerCondition(time: TimeOfDay(hours: 17, minutes: 0)),
      );
      (c.toString()).should.be('on 2026-06-30 at 17:00');
    });

    test('Then AfterPeriodCondition toString', () {
      const c = AfterPeriodCondition(period: 'PT4H');
      (c.toString()).should.be('after PT4H');
    });

    test('Then EveryTimeCondition toString', () {
      const c = EveryTimeCondition(period: 'P1W');
      (c.toString()).should.be('every P1W');
    });

    test('Then EveryTimeCondition with times limit', () {
      const c = EveryTimeCondition(period: 'PT1H', times: 24);
      (c.toString()).should.be('24 times every PT1H');
    });

    test('Then CronTimerCondition toString', () {
      const c = CronTimerCondition('0 9 * * MON-FRI');
      (c.toString()).should.be('cron "0 9 * * MON-FRI"');
    });
  });

  // =========================================================================
  // Process entities
  // =========================================================================

  group('Given WfLane', () {
    test('Then lane holds elements', () {
      final task = WfTask.generic(name: 'ProcessOrder');
      final lane = WfLane(id: const NodeId('Sales'), elements: [task]);
      lane.elements.should.haveCount(1);
      identical(lane.elements.first, task).should.beTrue();
    });
  });

  group('Given WfProcess', () {
    test('Then process with lanes', () {
      final salesLane = WfLane(
        id: const NodeId('Sales'),
        elements: [WfTask.generic(name: 'ProcessOrder')],
      );
      final p = WfProcess(
        id: const NodeId('OrderToDeliveryWorkflow'),
        elements: [salesLane],
      );
      p.hasLanes.should.beTrue();
      p.lanes.should.haveCount(1);
      (p.lanes.first.id.value).should.be('Sales');
    });

    test('Then process without lanes', () {
      final p = WfProcess(
        id: const NodeId('SimpleProcess'),
        elements: [WfTask.generic(name: 'DoWork')],
      );
      p.hasLanes.should.beFalse();
    });
  });

  group('Given WorkflowCompilationUnit', () {
    test('Then fully qualified name with package', () {
      final cu = WorkflowCompilationUnit(
        package: PackagePath.parse(dotSeparated: 'de.monticore.bpmn.examples'),
        process: const WfProcess(id: NodeId('OrderToDeliveryWorkflow')),
      );
      cu.fullyQualifiedName.should.be(
        'de.monticore.bpmn.examples.OrderToDeliveryWorkflow',
      );
    });

    test('Then fully qualified name without package', () {
      final cu = const WorkflowCompilationUnit(
        process: WfProcess(id: NodeId('Simple')),
      );
      (cu.fullyQualifiedName).should.be('Simple');
    });

    test('Then imports are stored', () {
      final cu = const WorkflowCompilationUnit(
        process: WfProcess(id: NodeId('P')),
        imports: [
          ImportStatement(
            path: 'de.monticore.bpmn.cds.OrderToDelivery',
            wildcard: true,
          ),
        ],
      );
      cu.imports.first.wildcard.should.beTrue();
    });
  });

  // =========================================================================
  // CD domain entities
  // =========================================================================

  group('Given CdAttribute', () {
    test('Then public attribute', () {
      final a = CdAttribute.public('orderID', 'String');
      (a.visibility).should.be(CdVisibility.public);
      a.isDerived.should.beFalse();
      (a.toString()).should.be('public String orderID;');
    });

    test('Then derived attribute', () {
      final a = CdAttribute.derived('workingDays', 'int');
      a.isDerived.should.beTrue();
      (a.toString()).should.be('/int workingDays;');
    });

    test('Then package-local attribute has no visibility keyword', () {
      const a = CdAttribute(
        name: 'hiringDate',
        type: 'java.time.ZonedDateTime',
      );
      (a.visibility).should.be(CdVisibility.packageLocal);
      (a.toString()).should.be('java.time.ZonedDateTime hiringDate;');
    });
  });

  group('Given CdMethod', () {
    test('Then public method signature', () {
      final m = const CdMethod(
        name: 'checkAvailability',
        returnType: 'boolean',
        parameters: [
          CdMethodParameter(name: 'productID', type: 'String'),
          CdMethodParameter(name: 'qty', type: 'int'),
        ],
        visibility: CdVisibility.public,
      );
      m.parameters.should.haveCount(2);
      m.toString().should.be(
        'public boolean checkAvailability(String productID, int qty);',
      );
    });
  });

  group('Given CdMultiplicity', () {
    test('Then one toString', () {
      (CdMultiplicity.one.toString()).should.be('[1]');
    });
    test('Then many toString', () {
      (CdMultiplicity.many.toString()).should.be('[*]');
    });
    test('Then optional toString', () {
      (CdMultiplicity.optional.toString()).should.be('[0..1]');
    });
    test('Then atLeastOne toString', () {
      (CdMultiplicity.atLeastOne.toString()).should.be('[1..*]');
    });
    test('Then range toString', () {
      (CdMultiplicity.range(2, 5).toString()).should.be('[2..5]');
    });
  });

  group('Given CdAssociation', () {
    test('Then one-to-many factory', () {
      final a = CdAssociation.oneToMany(
        source: 'LeaveCard',
        target: 'LeaveEntry',
        roleName: 'entries',
      );
      (a.sourceMultiplicity).should.be(CdMultiplicity.one);
      (a.targetMultiplicity).should.be(CdMultiplicity.many);
      (a.roleName).should.be('entries');
      a.toString().should.be(
        'association [1] LeaveCard -> entries LeaveEntry [*];',
      );
    });

    test('Then one-to-one factory', () {
      final a = CdAssociation.oneToOne(
        source: 'CustomerDeliveryAgreement',
        target: 'DestinationAddress',
      );
      (a.targetMultiplicity).should.be(CdMultiplicity.one);
    });
  });

  group('Given CdClass', () {
    test('Then public data class', () {
      final c = CdClass.publicData(
        name: 'Order',
        attributes: [
          CdAttribute.public('orderID', 'String'),
          CdAttribute.public('numberOfOrderedProducts', 'int'),
          CdAttribute.public('totalCost', 'double'),
        ],
      );
      (c.visibility).should.be(CdVisibility.public);
      c.attributes.should.haveCount(3);
      c.isAbstract.should.beFalse();
    });

    test('Then abstract class', () {
      const c = CdClass(name: 'AbstractProcessor', isAbstract: true);
      c.isAbstract.should.beTrue();
    });

    test('Then class with superclass and interfaces', () {
      const c = CdClass(
        name: 'SpecialOrder',
        superClass: 'Order',
        interfaces: ['Trackable', 'Auditable'],
      );
      (c.superClass).should.be('Order');
      c.interfaces.should.contain('Trackable');
    });
  });

  group('Given CdInterface', () {
    test('Then interface with methods', () {
      final iface = const CdInterface(
        name: 'Trackable',
        methods: [
          CdMethod(
            name: 'getTrackingNumber',
            returnType: 'String',
            visibility: CdVisibility.public,
          ),
        ],
      );
      iface.methods.should.haveCount(1);
    });
  });

  group('Given CdEnum', () {
    test('Then enum with constants', () {
      const e = CdEnum(
        name: 'PaymentMethod',
        constants: [
          CdEnumConstant(name: 'CREDIT_CARD'),
          CdEnumConstant(name: 'DEBIT_CARD'),
          CdEnumConstant(name: 'BANK_TRANSFER'),
        ],
      );
      e.constants.should.haveCount(3);
      e.constants.map((c) => c.name).should.containAll([
        'CREDIT_CARD',
        'DEBIT_CARD',
        'BANK_TRANSFER',
      ]);
    });
  });

  group('Given CdClassDiagram — OrderToDelivery', () {
    // Represents the full OrderToDelivery.cd diagram as domain entities
    late CdClassDiagram diagram;

    setUp(() {
      diagram = CdClassDiagram(
        name: 'OrderToDelivery',
        package: PackagePath.parse(dotSeparated: 'de.monticore.bpmn.cds'),
        classifiers: [
          CdClass.publicData(
            name: 'InventoryAvailabilityChecker',
            attributes: [
              CdAttribute.public('allProductsAvailable', 'boolean'),
              CdAttribute.public('unavailableProducts', 'List<Product>'),
            ],
          ),
          CdClass.publicData(
            name: 'Order',
            attributes: [
              CdAttribute.public('orderID', 'String'),
              CdAttribute.public('customerID', 'String'),
              CdAttribute.public('numberOfOrderedProducts', 'int'),
              CdAttribute.public('orderList', 'List<Product>'),
              CdAttribute.public('checker', 'InventoryAvailabilityChecker'),
              CdAttribute.public('totalCost', 'double'),
            ],
          ),
          CdClass.publicData(
            name: 'Product',
            attributes: [
              CdAttribute.public('productID', 'String'),
              CdAttribute.public('name', 'String'),
              CdAttribute.public('orderQuantity', 'int'),
            ],
          ),
          CdClass.publicData(
            name: 'CustomerDeliveryAgreement',
            attributes: [
              CdAttribute.public('customerID', 'String'),
              CdAttribute.public('isOrderPickedUp', 'boolean'),
              CdAttribute.public('address', 'DestinationAddress'),
            ],
          ),
          CdClass.publicData(
            name: 'DestinationAddress',
            attributes: [
              CdAttribute.public('street', 'String'),
              CdAttribute.public('houseNumber', 'String'),
              CdAttribute.public('postalCode', 'String'),
              CdAttribute.public('city', 'String'),
            ],
          ),
          CdClass.publicData(
            name: 'PaymentValidityChecker',
            attributes: [
              CdAttribute.public('paymentValid', 'boolean'),
              CdAttribute.public('cardNumberValid', 'boolean'),
              CdAttribute.public('cardVerificationValueValid', 'boolean'),
              CdAttribute.public('paymentMethod', 'String'),
              CdAttribute.public('cardNumber', 'String'),
              CdAttribute.public('cardVerificationValue', 'String'),
              CdAttribute.public('cardExpirationDate', 'String'),
            ],
          ),
        ],
      );
    });

    test('Then has 6 classes', () {
      diagram.classes.should.haveCount(6);
    });

    test('Then findClassifier finds Order', () {
      final c = diagram.findClassifier('Order');
      c.should.not.beNull();
      (c!.name).should.be('Order');
    });

    test('Then Order has 6 attributes', () {
      final order = diagram.findClassifier('Order') as CdClass;
      order.attributes.should.haveCount(6);
    });

    test('Then PaymentValidityChecker has allProductsAvailable-like field', () {
      final pvc = diagram.findClassifier('PaymentValidityChecker') as CdClass;
      final field = pvc.attributes.firstWhere((a) => a.name == 'paymentValid');
      (field.type).should.be('boolean');
    });

    test('Then fullyQualifiedName is correct', () {
      diagram
          .fullyQualifiedName('Order')
          .should
          .be('de.monticore.bpmn.cds.OrderToDelivery.Order');
    });
  });

  group('Given CdClassDiagram — Domain (HR)', () {
    late CdClassDiagram diagram;

    setUp(() {
      diagram = CdClassDiagram(
        name: 'Domain',
        package: PackagePath.parse(dotSeparated: 'de.monticore.bpmn.cds'),
        classifiers: [
          const CdClass(
            name: 'Contract',
            attributes: [
              CdAttribute(name: 'hiringDate', type: 'java.time.ZonedDateTime'),
              CdAttribute(
                name: 'version',
                type: 'int',
                visibility: CdVisibility.public,
              ),
            ],
          ),
          const CdClass(name: 'DomainUser'),
          CdClass.publicData(
            name: 'Report',
            attributes: [
              CdAttribute.public('result', 'String'),
              CdAttribute.public('details', 'String'),
            ],
          ),
          const CdClass(name: 'LeaveCard'),
          CdClass(
            name: 'LeaveEntry',
            attributes: [
              const CdAttribute(
                name: 'startDate',
                type: 'java.time.ZonedDateTime',
              ),
              const CdAttribute(
                name: 'endDate',
                type: 'java.time.ZonedDateTime',
              ),
              CdAttribute.derived('workingDays', 'int'),
              CdAttribute.derived('remainingLeaveDays', 'int'),
              const CdAttribute(name: 'valid', type: 'boolean'),
              const CdAttribute(name: 'approved', type: 'boolean'),
            ],
          ),
          CdClass.publicData(
            name: 'MedicalCertificate',
            attributes: [
              const CdAttribute(
                name: 'startDate',
                type: 'java.time.ZonedDateTime',
              ),
              const CdAttribute(
                name: 'endDate',
                type: 'java.time.ZonedDateTime',
              ),
              CdAttribute.public('description', 'String'),
            ],
          ),
        ],
        associations: [
          CdAssociation.oneToMany(source: 'DomainUser', target: 'Contract'),
          CdAssociation.oneToMany(
            source: 'LeaveCard',
            target: 'LeaveEntry',
            roleName: 'entries',
          ),
          CdAssociation.oneToOne(source: 'LeaveCard', target: 'DomainUser'),
        ],
      );
    });

    test('Then has 6 classifiers', () {
      diagram.classifiers.should.haveCount(6);
    });

    test('Then LeaveEntry has derived attributes', () {
      final le = diagram.findClassifier('LeaveEntry') as CdClass;
      final derived = le.attributes.where((a) => a.isDerived).toList();
      derived.should.haveCount(2);
      derived.map((a) => a.name).should.containAll([
        'workingDays',
        'remainingLeaveDays',
      ]);
    });

    test('Then has 3 associations', () {
      diagram.associations.should.haveCount(3);
    });

    test('Then entries association has role name', () {
      final assoc = diagram.associations.firstWhere(
        (a) => a.roleName == 'entries',
      );
      (assoc.sourceType).should.be('LeaveCard');
      (assoc.targetType).should.be('LeaveEntry');
    });
  });

  // =========================================================================
  // Failures
  // =========================================================================

  group('Given WorkflowFailure', () {
    test('Then DeadNode message', () {
      const f = DeadNode(nodeId: NodeId('OrphanTask'));
      f.message.should.contain('OrphanTask');
      f.message.should.contain('unreachable');
    });

    test('Then MergeGatewayTooFewIncomingFlows message', () {
      const f = MergeGatewayTooFewIncomingFlows(
        gatewayId: NodeId('MergeWork'),
        found: 1,
      );
      f.message.should.contain('MergeWork');
      f.message.should.contain('1 incoming');
    });

    test('Then LackOfSync message', () {
      const f = LackOfSync(mergeGatewayId: NodeId('MergeWork'));
      f.message.should.contain('MergeWork');
      f.message.should.contain('XOR');
    });

    test('Then ParallelBranchesClosedWithXor message', () {
      const f = ParallelBranchesClosedWithXor(
        mergeGatewayId: NodeId('MergeWork'),
        parallelBranch: [NodeId('Introduction'), NodeId('MergeWork')],
      );
      f.message.should.contain('MergeWork');
      f.message.should.contain('XOR');
    });

    test('Then TaskNotIncarnated message', () {
      const f = TaskNotIncarnated(taskId: NodeId('LiteratureReview'));
      f.message.should.contain('LiteratureReview');
      f.message.should.contain('reference model');
    });

    test('Then UnresolvedNodeReference message', () {
      const f = UnresolvedNodeReference(
        referencedNode: NodeId('MissingNode'),
        fromFlow: NodeId('flow1'),
      );
      f.message.should.contain('MissingNode');
      f.message.should.contain('undefined');
    });

    test('Then ProcessNotSound message', () {
      const f = ProcessNotSound(
        reason: 'path from start cannot reach end event',
      );
      f.message.should.contain('not sound');
    });

    test('Then InfiniteLoop message', () {
      const f = InfiniteLoop(
        loopNodes: [NodeId('A'), NodeId('B'), NodeId('A')],
      );
      f.message.should.contain('A → B → A');
    });

    test('Then failures are equatable', () {
      const a = DeadNode(nodeId: NodeId('X'));
      const b = DeadNode(nodeId: NodeId('X'));
      const c = DeadNode(nodeId: NodeId('Y'));
      a.should.be(b);
      a.should.not.be(c);
    });
  });
}
