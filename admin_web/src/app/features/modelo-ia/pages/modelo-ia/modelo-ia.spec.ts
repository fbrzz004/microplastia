import { ComponentFixture, TestBed } from '@angular/core/testing';
import { ModeloIa } from './modelo-ia';

describe('ModeloIa', () => {
  let component: ModeloIa;
  let fixture: ComponentFixture<ModeloIa>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [ModeloIa],
    }).compileComponents();

    fixture = TestBed.createComponent(ModeloIa);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
